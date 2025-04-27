{ disks ? [ "/dev/nvme0n1" ], ... }:
{
  disko.devices = {
    disk = {
      x = {
        device = builtins.elemAt disks 0;
        type = "disk";
        content = {
          type = "table";
          format = "gpt";
          partitions = {
            # boot
            ESP = {
              start = "1MiB";
              end = "500MiB";
              bootable = true;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            # root
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
    };
    zpool = {
      zroot = {
        type = "zpool";
        mode = "mirror";
        options.cachefile = "none";
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
        };
        moutpoint = "/";
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zroot@blank$' || zfs snapshot zroot@blank";

        datasets = {
          "nix" = {
            type = "zfs_fs";
            options.mountpoint = "/local/nix";
            mountpoint = "/local/nix";
          };
          "home" = {
            type = "zfs_fs";
            options.mountpoint = "/safe/home";
            mountpoint = "/safe/home";
          };
          "persist" = {
            type = "zfs_fs";
            options.mountpoint = "/safe/persist";
            mountpoint = "/safe/persist";
          };
        };
      };
    };
  };
}
