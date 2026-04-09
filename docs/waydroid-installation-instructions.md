# Waydroid Installation Instructions

Use the low-risk path: add a second official kernel with binder support, boot into it, then install Waydroid. Keep your current kernel installed as fallback.

## 1. Install a secondary kernel and headers

```bash
sudo pacman -Syu
sudo pacman -S linux-zen linux-zen-headers
```

## 2. Reboot and select the `linux-zen` boot entry

After reboot, choose the `linux-zen` kernel from your boot menu.

## 3. Confirm binder support after booting into `linux-zen`

```bash
uname -r
zgrep CONFIG_ANDROID_BINDER_IPC /proc/config.gz
```

You want:

```text
CONFIG_ANDROID_BINDER_IPC=y
```

or:

```text
CONFIG_ANDROID_BINDER_IPC=m
```

## 4. Install Waydroid

```bash
sudo pacman -S waydroid
```

## 5. Initialize the container

Standard initialization:

```bash
sudo waydroid init
```

If you want Google apps:

```bash
sudo waydroid init -s GAPPS
```

## 6. Start and enable the Waydroid container service

```bash
sudo systemctl enable --now waydroid-container.service
```

## 7. Launch Waydroid

```bash
waydroid show-full-ui
```

## Useful follow-ups

Start a session manually if needed:

```bash
waydroid session start
```

Install an APK:

```bash
waydroid app install /path/to/app.apk
```

## If binder support is still missing

Run:

```bash
zgrep CONFIG_ANDROID_BINDER_IPC /proc/config.gz
```

If it is not `y` or `m`, stop there and reassess before trying DKMS or other kernel changes.
