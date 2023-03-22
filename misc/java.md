# Setup Java

1. Run below to install Open JDK 11 (or 8 if you want)

```bash
sudo apt install openjdk-8-jdk-headless gradle
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
```

2. Install Command Line Tools (Visit [Here](https://developer.android.com/studio#downloads))

```bash
cd ~ # Make sure you are at home!
curl https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip -o /tmp/cmd-tools.zip
mkdir -p android/cmdline-tools
unzip -q -d android/cmdline-tools /tmp/cmd-tools.zip
mv android/cmdline-tools/cmdline-tools android/cmdline-tools/latest
rm /tmp/cmd-tools.zip # delete the zip file (optional)
```

3. Put this in your `~/.zshrc`

```
export ANDROID_HOME=$HOME/android
export ANDROID_SDK_ROOT=${ANDROID_HOME}
export PATH=${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${PATH}
```

4. Run

```
yes | sdkmanager --licenses
sdkmanager --update
sdkmanager "platform-tools" "platforms;android-31" "build-tools;30.0.3"
```

5. Install gradle (probably not need this since we already installed from the first step)

```bash
mkdir tmp

# https://services.gradle.org/distributions/
wget -c https://services.gradle.org/distributions/gradle-7.4.2-bin.zip

sudo unzip -d /opt/gradle gradle-7.4.2-bin.zip

export GRADLE_HOME=/opt/gradle/gradle-7.4.2
export PATH=${GRADLE_HOME}/bin:${PATH}

gradle --version
```
