{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
  makeWrapper,
  pkg-config,
  openssl,
  darwin,
  maa-assistant-arknights,
  android-tools,
  git,
}:

rustPlatform.buildRustPackage rec {
  pname = "maa-cli";
  version = "0.4.12";

  src = fetchFromGitHub {
    owner = "MaaAssistantArknights";
    repo = "maa-cli";
    rev = "v${version}";
    hash = "sha256-cq1FCsBHwcL8a51MswG/5TvyzSbtOvqw06OZfIXDVwg=";
  };

  nativeBuildInputs = [
    installShellFiles
    makeWrapper
    pkg-config
  ];

  buildInputs =
    [ openssl ]
    ++ lib.optionals stdenv.isDarwin (
      with darwin.apple_sdk.frameworks;
      [
        Security
        SystemConfiguration
      ]
    );

  # https://github.com/MaaAssistantArknights/maa-cli/pull/126
  buildNoDefaultFeatures = true;
  buildFeatures = [ "git2" ];

  cargoHash = "sha256-eXgZt8sLbHkVNWqFv8Zdq7xrFBi1YhKI8Js0OT2Npi8=";

  # maa-cli would only seach libMaaCore.so and resources in itself's path
  # https://github.com/MaaAssistantArknights/maa-cli/issues/67
  postInstall =
    ''
      mkdir -p $out/share/maa-assistant-arknights/
      ln -s ${maa-assistant-arknights}/share/maa-assistant-arknights/* $out/share/maa-assistant-arknights/
      ln -s ${maa-assistant-arknights}/lib/* $out/share/maa-assistant-arknights/
      mv $out/bin/maa $out/share/maa-assistant-arknights/

      makeWrapper $out/share/maa-assistant-arknights/maa $out/bin/maa \
        --prefix PATH : "${
          lib.makeBinPath [
            android-tools
            git
          ]
        }"

    ''
    + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
      installShellCompletion --cmd maa \
        --bash <($out/bin/maa complete bash) \
        --fish <($out/bin/maa complete fish) \
        --zsh <($out/bin/maa complete zsh)

      mkdir -p manpage
      $out/bin/maa mangen --path manpage
      installManPage manpage/*
    '';

  meta = with lib; {
    description = "Simple CLI for MAA by Rust";
    homepage = "https://github.com/MaaAssistantArknights/maa-cli";
    license = licenses.agpl3Only;
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = with maintainers; [ Cryolitia ];
    mainProgram = "maa";
  };
}
