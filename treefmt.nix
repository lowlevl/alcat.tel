{...}: {
  programs.alejandra.enable = true;
  programs.rustfmt.enable = true;
  programs.sqlfluff.dialect = "sqlite";
}
