﻿using System.Text;
using BusinessObjects.Models;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Repositories.Implementation;
using Repositories.Interface;
using Services.Implementation;
using Services.Interface;

namespace API.Extensions;

public static class ServiceExtensions
{
    public static IServiceCollection ConfigureRepositories(this IServiceCollection services)
    {
        services.AddScoped<IUnitOfWork, UnitOfWork>();
        return services;
    }

    public static IServiceCollection ConfigureServices(this IServiceCollection services)
    {
        services.AddScoped<IProductService, ProductService>();
        services.AddScoped<ICancelReasonService, CancelReasonService>();
        services.AddScoped<IProductImageService, ProductImageService>();
        services.AddScoped<IAddressService, AddressService>();
        services.AddScoped<IProductStatusService, ProductStatusService>();
        services.AddScoped<IProductCategoryService, ProductCategoryService>();
        services.AddScoped<IAuthenticationService, AuthenticationService>();
        services.AddScoped<ITokenService, TokenService>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IReviewService, ReviewService>();
        services.AddScoped<IReplyService, ReplyService>();
        services.AddScoped<ICartItemService, CartItemService>();
        services.AddScoped<IPaymentMethodService, PaymentMethodService>();
        services.AddScoped<IVariationService, VariationService>();
        services.AddScoped<IVariationOptionService, VariationOptionService>();
        services.AddScoped<IProductItemService, ProductItemService>();
        services.AddScoped<IBlogService, BlogService>();
        services.AddScoped<IOrderService, OrderService>();
        services.AddScoped<IVNPayService, VNPAYService>();
        services.AddScoped<IProductForSkinTypeService, ProductForSkinTypeService>();
        services.AddScoped<IQuizSetService, QuizSetService>();
        services.AddScoped<IQuizResultService, QuizResultService>();
        services.AddScoped<ISkinTypeService, SkinTypeService>();
        services.AddScoped<IBrandService, BrandService>();
        services.AddScoped<ICountryService, CountryService>();
        services.AddScoped<ICountryRepository, CountryRepository>();
        services.AddScoped<IAccountService, AccountService>();
        services.AddScoped<IRoleService, RoleService>();
        services.AddScoped<IImageService, ImageService>();
        services.AddScoped<IQuizOptionService, QuizOptionService>();
        services.AddScoped<IQuizQuestionService, QuizQuestionService>();
        services.AddScoped<IVoucherService, VoucherService>();
        services.AddScoped<IDashboardService, DashboardService>();

        // Add Face++ skin analysis services
        services.AddScoped<FacePlusPlusClient>();
        services.AddScoped<ISkinAnalysisService, SkinAnalysisService>();

        // Add TensorFlow skin analysis service
        services.AddScoped<TensorFlowSkinAnalysisService>();
        
        // Add Transaction service
        services.AddScoped<ITransactionService, TransactionService>();
        services.AddScoped<IChatHistoryService, ChatHistoryService>();
        
        return services;
    }

    public static IServiceCollection ConfigureJwtAuthentication(this IServiceCollection services, IConfiguration configuration)
    {
        // Configure JWT authentication
        services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            })
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ValidIssuer = configuration["Jwt:Issuer"],
                    ValidAudience = configuration["Jwt:Audience"],
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(configuration["Jwt:Key"])),
                    ClockSkew = TimeSpan.Zero
                };

                // Configure to handle expired tokens gracefully
                options.Events = new JwtBearerEvents
                {
                    OnAuthenticationFailed = context =>
                    {
                        if (context.Exception.GetType() == typeof(SecurityTokenExpiredException))
                        {
                            context.Response.Headers.Add("Token-Expired", "true");
                        }
                        return Task.CompletedTask;
                    },
                    OnMessageReceived = context =>
                    {
                        // Lấy token từ query string cho SignalR
                        var accessToken = context.Request.Query["access_token"];
                        var path = context.HttpContext.Request.Path;
                        
                        // Kiểm tra xem request có phải cho SignalR Hub không
                        if (!string.IsNullOrEmpty(accessToken) && 
                            (path.StartsWithSegments("/chathub") || path.StartsWithSegments("/transactionhub")))
                        {
                            // Đặt token để hệ thống xác thực
                            context.Token = accessToken;
                        }
                        
                        return Task.CompletedTask;
                    }
                };
            });

        // Configure Swagger to use JWT
        services.ConfigureSwaggerForJwt();

        return services; 
    }

    public static void ConfigureSwaggerForJwt(this IServiceCollection services)
    {
        services.AddSwaggerGen(c =>
        {
            c.SwaggerDoc("v1", new OpenApiInfo
            {
                Title = "API",
                Version = "v1",
                Description = "A sample ASP.NET Core API with JWT authentication",
                Contact = new OpenApiContact
                {
                    Name = "Your Name",
                    Email = "your-email@example.com",
                    Url = new Uri("https://example.com")
                }
            });

            // Add JWT Authentication
            c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
            {
                Description = "JWT Authorization header using the Bearer scheme. Example: \"Authorization: Bearer {token}\"",
                Name = "Authorization",
                In = ParameterLocation.Header,
                Type = SecuritySchemeType.ApiKey,
                Scheme = "Bearer"
            });

            c.AddSecurityRequirement(new OpenApiSecurityRequirement
            {
                {
                    new OpenApiSecurityScheme
                    {
                        Reference = new OpenApiReference
                        {
                            Type = ReferenceType.SecurityScheme,
                            Id = "Bearer"
                        }
                    },
                    Array.Empty<string>()
                }
            });
        });
    }

    public static IServiceCollection ConfigureDbContext(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<SPSSContext>(options =>
        {
            options.UseSqlServer(configuration.GetConnectionString("SPSS"));
        }, ServiceLifetime.Scoped);
        
        // Register IConfiguration for the DbContext to use
        services.AddScoped<SPSSContext>((provider) => {
            var options = provider.GetRequiredService<DbContextOptions<SPSSContext>>();
            return new SPSSContext(options, configuration);
        });
        
        return services;
    }
    
    public static IServiceCollection ConfigureCors(this IServiceCollection services)
    {
        services.AddCors(options =>
        {
            options.AddPolicy("AllowFrontendApp",
                policy =>
                {
                    policy.WithOrigins("http://localhost:3000")
                        .AllowAnyHeader()
                        .AllowAnyMethod()
                        .AllowCredentials();
                });
            
            options.AddPolicy("AllowAll", builder =>
            {
                builder
                    .SetIsOriginAllowed(_ => true) // Cho phép tất cả nguồn gốc
                    .AllowAnyMethod()
                    .AllowAnyHeader()
                    .AllowCredentials(); // Quan trọng cho WebSocket/SignalR
            });
        });
        return services;
    }
}
