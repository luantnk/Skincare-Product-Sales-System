﻿using BusinessObjects.Dto.User;

namespace BusinessObjects.Dto.Authentication;

public class AuthenticationResponse
{
    public string AccessToken { get; set; }
    public string RefreshToken { get; set; }
    // public AuthUserDto AuthUserDto { get; set; }
}