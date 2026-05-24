#!/usr/libexec/bluebuild/nu/nu

const flathubURL = "https://dl.flathub.org/repo/flathub.flatpakrepo"

const defaultConfiguration = {
    notify: true
    scope: user
    repo: {
        url: $flathubURL
        name: "flathub"
        title: "Flathub"
    }
    install: []
}

const usrSharePath = "/usr/share/bluebuild/default-flatpaks"
const libExecPath = "/usr/libexec/bluebuild/default-flatpaks"
const configPath = $"($usrSharePath)/configuration.yaml"

def main [configStr: string] {
    let config = $configStr | from yaml
    
    if ('user' in $config or 'system' in $config) {
        print $"(ansi red_bold)CONFIGURATION ERROR(ansi reset)"
        print $"(ansi yellow_reverse)HINT(ansi reset): the default-flatpaks module has been updated with breaking changes!"
        print $"It seems like you are trying to run the new (ansi default_italic)default-flatpaks@v2(ansi reset) module with configuration made for the older version."
        print $"You can read the docs to migrate to the new and improved module, or just change switch back to the old module like this (ansi default_italic)type: default-flatpaks@v1(ansi reset)"
        exit 1
    }

    let configurations = $config.configurations | each {|configuration|
        mut merged = $defaultConfiguration | merge $configuration
        $merged.repo = $defaultConfiguration.repo | merge $merged.repo # make sure all repo properties exist

        print $"Validating configuration of (ansi default_italic)($merged.install | length)(ansi reset) Flatpaks from (ansi default_italic)($merged.repo.title)(ansi reset)"

        if (not ($merged.scope == "system" or $merged.scope == "user")) {
            print $"(ansi red_bold)Scope must be either(ansi reset) (ansi blue_italic)system(ansi reset) (ansi red_bold)or(ansi reset) (ansi blue_italic)user(ansi reset)"
            print $"(ansi blue)Your input:(ansi reset) ($merged.scope)"
            exit 1
        }
        if (not ($merged.notify == true or $merged.notify == false)) {
            print $"(ansi red_bold)Notify must be either(ansi reset) (ansi blue_italic)true(ansi reset) (ansi red_bold)or(ansi reset) (ansi blue_italic)false(ansi reset)"
            print $"(ansi blue)Your input:(ansi reset) ($merged.notify)"
            exit 1
        }
        if ($merged.repo.url == $flathubURL) {
            checkFlathub $merged.install
        }

        print $"Validation successful!"

        $merged
    }


    if (not ($configPath | path exists)) {
        mkdir ($configPath | path dirname)
        '[]'| save $configPath
    }

    open $configPath
        | append $configurations
        | to yaml | save -f $configPath

    print $"(ansi green_bold)Successfully generated following configurations:(ansi reset)"
    print ($configurations | to yaml)

    print "Setting up Flatpak setup services..."

    mkdir /usr/lib/systemd/system/
    cp $"($env.MODULE_DIRECTORY)/default-flatpaks/post-boot/system-flatpak-setup.service" /usr/lib/systemd/system/system-flatpak-setup.service
    cp $"($env.MODULE_DIRECTORY)/default-flatpaks/post-boot/system-flatpak-setup.timer" /usr/lib/systemd/system/system-flatpak-setup.timer
    mkdir /usr/lib/systemd/user/
    cp $"($env.MODULE_DIRECTORY)/default-flatpaks/post-boot/user-flatpak-setup.service" /usr/lib/systemd/user/user-flatpak-setup.service
    cp $"($env.MODULE_DIRECTORY)/default-flatpaks/post-boot/user-flatpak-setup.timer" /usr/lib/systemd/user/user-flatpak-setup.timer
    systemctl enable --force system-flatpak-setup.timer
    systemctl enable --force --global user-flatpak-setup.timer

    mkdir ($libExecPath)
    cp $"($env.MODULE_DIRECTORY)/default-flatpaks/post-boot/system-flatpak-setup" $"($libExecPath)/system-flatpak-setup" 
    cp $"($env.MODULE_DIRECTORY)/default-flatpaks/post-boot/user-flatpak-setup" $"($libExecPath)/user-flatpak-setup" 
    chmod +x $"($libExecPath)/system-flatpak-setup"
    chmod +x $"($libExecPath)/user-flatpak-setup"

    cp $"($env.MODULE_DIRECTORY)/default-flatpaks/post-boot/bluebuild-flatpak-manager" "/usr/bin/bluebuild-flatpak-manager"
    chmod +x "/usr/bin/bluebuild-flatpak-manager"
}

def retry [
  --sleep-duration(-d): duration = 2sec # The duration to sleep until another retry
  --count(-c): int = 6 # How many retries should be done
  --backoff(-b): int = 2 # Backoff multiplier for each retry
  operation: closure # The closure to retry
]: nothing -> any {
    mut delay = $sleep_duration
    for attempt in 0..$count {
        try {
            return (do $operation)
        } catch {|err|
            let remaining = $count - $attempt
            if ($remaining == 0) {
                return (error make {
                    msg: $"Failed to run closure:\n($err.msg)"
                    label: {
                        span: (metadata $operation).span
                        text: 'Failed closure'
                    }
                })
            }

            print $"Retrying closure in (ansi green)($delay)(ansi reset) (ansi cyan)($remaining)(ansi reset) more time\(s\)"
            sleep $delay
            $delay = $delay * $backoff
        }
    }
}

def isTransientNetworkError [message: string] {
    let msg = $message | str downcase
    ($msg | str contains "network failure")
        or ($msg | str contains "i/o error")
        or ($msg | str contains "timed out")
        or ($msg | str contains "timeout")
        or ($msg | str contains "connection reset")
        or ($msg | str contains "temporary failure")
}

def checkFlathub [packages: list<string>] {
    print "Checking if configured packages exist on Flathub..."
    let results = $packages | each { |package|
        let id = $package | split row "/" | get 0
        try {
            let _ = retry -c 6 -d 2sec { http get --max-time 10sec $"https://flathub.org/api/v2/stats/($id)" }
            { package: $package, status: "ok" }
        } catch {|err|
            let msg = $err.msg | default ""
            if (isTransientNetworkError $msg) {
                print -e $"Transient network error while checking (ansi default_italic)($id)(ansi reset). Skipping availability validation for this package."
                { package: $package, status: "skipped" }
            } else {
                print -e $"Error checking flatpak:\n($msg)"
                { package: $package, status: "missing" }
            }
        }
    }
    let unavailablePackages = $results | where status == "missing" | each {|row| $row.package }
    let skippedPackages = $results | where status == "skipped" | each {|row| $row.package }
    if ($skippedPackages | length) > 0 {
        print $"(ansi yellow_bold)Warning:(ansi reset) Skipped Flathub availability checks for (ansi default_italic)($skippedPackages | length)(ansi reset) package(s) due to transient network errors."
    }
    if ($unavailablePackages | length) > 0 {
        print $"(ansi red_bold)The following packages are not available on Flathub, which is the specified repository for them to be installed from:(ansi reset) "
        for package in $unavailablePackages {
            print $"(ansi default_italic)($package)(ansi reset)"
        }
        exit 1
    }
}
