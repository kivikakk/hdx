inputs@{...}:
let
  python = (inputs.python.override { includeSiteCustomize = false; }).overrideAttrs (finalAttrs: prevAttrs: {
    postInstall = prevAttrs.postInstall + ''
      # Override sitecustomize.py with our NIX_PYTHONPATH-preserving variant.
      cp ${../patches/sitecustomize.py} $out/${finalAttrs.passthru.sitePackages}/sitecustomize.py
    '';
  });
in
  python.override { self = python; }
