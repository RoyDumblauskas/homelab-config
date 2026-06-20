{ ... }: {
  programs.git = {
    enable = true;
    settings = {
      user.name = "Roy Dumblauskas";
      user.email = "roydumblauskas@gmail.com";
    };
  };
}
