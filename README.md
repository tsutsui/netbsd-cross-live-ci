# netbsd-cross-live-ci

**netbsd-cross-live-ci** is a GitHub Action that enables testing builds on NetBSD.
This action builds a live image of NetBSD during CI, sets up an emulator for the image,
and runs your project within the NetBSD environment.

## Features
- Automatically builds a NetBSD live image using source code and NetBSD cross toolchains during CI.
- Sets up an emulator (simh etc.) to run the live image.
- Executes build commands for your project in a NetBSD environment.

## Inputs

| Name           | Required | Default         | Description                                                      |
|----------------|----------|-----------------|------------------------------------------------------------------|
| `relrease`     | No       | `10.1`          | The NetBSD source version to use (e.g., `10.1`, `9.4`). |
| `machine`      | Yes      |                 | The architecture of the NetBSD environment (currently `alpha`, `i386`, `sparc`, `sparc64` and `vax` are supported). |
| `ftphost`      | No       | `cdn.NetBSD.org`| Hostname to download NetBSD source sets and binary sets from.  |
| `preapre`      | No       | `true`          | Commands for preparation of builds (install necessary packages via `pkg_add` etc.) |
| `configure`    | No       | `true`          | Commands for "configure" before builds (typically simple `configure` command) |
| `preapre`      | No       | `make && make install`| Commands to build your project |

## Outputs

This action does not produce specific outputs but ensures your project builds correctly on NetBSD and logs the results.

## Example Usage

Here is how to use **netbsd-cross-live-ci** in your GitHub Actions workflow:

```yaml
name: NetBSD CI

on:
  push:
  pull_request:

jobs:
  build-netbsd:
    runs-on: ubuntu-latest
    
      strategy:
      fail-fast: false
      matrix:
        machine: [alpha, i386, sparc, sparc64, vax]

    steps:
      - name: Build project in NetBSD/${{ matrix.machine }} environment
        uses: tsutsui/netbsd-cross-live-ci@master
        with:
          machine: "${{ matrix.machine }}"
          release: "10.1"

          prepare: |
            pkg_add perl

          configure: |
            sh configure

          build: |
            make
            make install

```

## Notes
1. **Live Image Generation**: The NetBSD live image is generated dynamically during the workflow based on the specified `netbsd-src`.
2. **Emulator Setup**: simh is used to run the NetBSD/vax live image, and qemu is used to run NetBSD/i386, NetBSD/sparc and NetBSD/sparc64. To run NetBSD/alpha, patched qemu-system-alpha binary is built during CI.
3. **PKG_PATH settings**: The default `PKG_PATH` environment variable is set in `/root/.profile`.

## License
See [LICENSE.txt](LICENSE.txt) file.

