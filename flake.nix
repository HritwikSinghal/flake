{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
	};

	outputs = { self, nixpkgs }: with nixpkgs.lib; with self.lib; let
		pkgsForSystem = system: import nixpkgs {
			inherit system;
			overlays = [ self.overlays.default ];
		};
	in {
		lib = import ./lib {inherit (nixpkgs) lib;};
		packages = genAttrs [
			"x86_64-linux"
			"aarch64-linux"
			"riscv64-linux"
		] (system: let
			pkgs = pkgsForSystem system;
		in (import ./pkgs {inherit pkgs system;}));

		nixosModules = import ./modules {
			lib = nixpkgs.lib // self.lib;
			inherit self;
		};

		overlays.default = final: prev: {
			illustris = self.packages.${prev.system};
			lib = prev.lib // self.lib;
		};

		devShells = genAttrs [ "x86_64-linux" ] (system: let
			pkgs = pkgsForSystem system;
		in {
			fpga = pkgs.mkShell {
				packages = with self.packages.${system}; [
					oss-cad-suite-bin vhd2vl
				];
			};
			ctf = pkgs.mkShell {
				shellHook = indent ''
					export PS1='>'$PS1
					export _JAVA_AWT_WM_NONREPARENTING=1
				'';
				packages = with pkgs; with python3Packages; [
					angr
					bintools-unwrapped
					ghidra
					pwntools
					radare2
					ropper
				];
			};
		});

		templates = genAttrs (dirs ./templates) ( name: {
			description = name;
			path = ./templates + "/${name}";
		});
	};
}
