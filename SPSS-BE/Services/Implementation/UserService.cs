using System.Text.Json;
using AutoMapper;
using AutoMapper;

using BusinessObjects.Dto.User;
using BusinessObjects.Models;
using Microsoft.EntityFrameworkCore;
using Repositories.Interface;
using Services.Interface;
using Services.Response;

namespace Services.Implementation;

public class UserService : IUserService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMapper _mapper;

    public UserService(IUnitOfWork unitOfWork, IMapper mapper)
    {
        _unitOfWork = unitOfWork;
        _mapper = mapper;
    }

    public async Task<UserDto> GetByIdAsync(Guid id)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(id);

        if (user == null || user.IsDeleted)
            throw new KeyNotFoundException($"User with ID {id} not found.");

        return _mapper.Map<UserDto>(user);
    }

    public async Task<UserDto> GetByEmailAsync(string email)
    {
        // Lấy thông tin user cùng với role
        var user = await _unitOfWork.Users
            .GetQueryable()
            .Include(u => u.Role) // Bao gồm thông tin Role
            .FirstOrDefaultAsync(u => u.EmailAddress == email);

        // Kiểm tra null
        if (user == null || user.IsDeleted)
            throw new KeyNotFoundException($"User with email {email} not found.");

        // Map thủ công từ User sang UserDto
        var userDto = new UserDto
        {
            UserId = user.UserId,
            UserName = user.UserName,
            SurName = user.SurName,
            LastName = user.LastName,
            EmailAddress = user.EmailAddress,
            PhoneNumber = user.PhoneNumber,
            AvatarUrl = user.AvatarUrl,
            Status = user.Status,
            Password = user.Password,
            SkinTypeId = user.SkinTypeId,
            RoleId = user.Role?.RoleId,
            Role = user.Role!.RoleName,
            CreatedBy = user.CreatedBy,
            LastUpdatedBy = user.LastUpdatedBy,
            DeletedBy = user.DeletedBy,
            CreatedTime = user.CreatedTime,
            LastUpdatedTime = user.LastUpdatedTime,
            DeletedTime = user.DeletedTime,
            IsDeleted = user.IsDeleted
        };

        return userDto;
    }

    public async Task<UserDto> GetByUserNameAsync(string userName)
    {
        // Lấy thông tin user cùng với role
        var user = await _unitOfWork.Users
            .GetQueryable()
            .Include(u => u.Role) // Bao gồm thông tin Role
            .FirstOrDefaultAsync(u => u.UserName == userName);

        // Kiểm tra null
        if (user == null || user.IsDeleted)
            throw new KeyNotFoundException($"User with user name {userName} not found.");

        // Map thủ công từ User sang UserDto
        var userDto = new UserDto
        {
            UserId = user.UserId,
            UserName = user.UserName,
            SurName = user.SurName,
            LastName = user.LastName,
            EmailAddress = user.EmailAddress,
            PhoneNumber = user.PhoneNumber,
            AvatarUrl = user.AvatarUrl,
            Status = user.Status,
            Password = user.Password, // Nếu trả về mật khẩu, hãy đảm bảo đã mã hóa
            SkinTypeId = user.SkinTypeId,
            RoleId = user.Role?.RoleId,
            Role = user.Role?.RoleName, // Gán tên vai trò từ bảng Role
            CreatedBy = user.CreatedBy,
            LastUpdatedBy = user.LastUpdatedBy,
            DeletedBy = user.DeletedBy,
            CreatedTime = user.CreatedTime,
            LastUpdatedTime = user.LastUpdatedTime,
            DeletedTime = user.DeletedTime,
            IsDeleted = user.IsDeleted
        };

        return userDto;
    }
    public async Task<PagedResponse<UserDto>> GetPagedAsync(int pageNumber, int pageSize)
    {
        var (users, totalCount) = await _unitOfWork.Users.GetPagedAsync(
            pageNumber,
            pageSize,
            u => u.IsDeleted == false // Only active users
        );

        var userDtos = _mapper.Map<IEnumerable<UserDto>>(users);

        return new PagedResponse<UserDto>
        {
            Items = userDtos,
            TotalCount = totalCount,
            PageNumber = pageNumber,
            PageSize = pageSize
        };
    }



    public async Task<UserDto> CreateAsync(UserForCreationDto? userForCreationDto)
    {
        
        // Log giá trị của UserForCreationDto
        Console.WriteLine($"UserName: {userForCreationDto.UserName}");
        Console.WriteLine($"SurName: {userForCreationDto.SurName}");
        Console.WriteLine($"LastName: {userForCreationDto.LastName}");
        Console.WriteLine($"EmailAddress: {userForCreationDto.EmailAddress}");
        Console.WriteLine($"PhoneNumber: {userForCreationDto.PhoneNumber}");
        Console.WriteLine($"Password: {userForCreationDto.Password}");
        
        
        if (userForCreationDto == null)
            throw new ArgumentNullException(nameof(userForCreationDto), "User data cannot be null.");
        
        // Check if the email already exists
        if (await CheckEmailExistsAsync(userForCreationDto.EmailAddress))
            throw new InvalidOperationException($"Email {userForCreationDto.EmailAddress} is already in use.");

        // Check if the username already exists
        if (await CheckUserNameExistsAsync(userForCreationDto.UserName))
            throw new InvalidOperationException($"Username {userForCreationDto.UserName} is already in use.");
        
        if (await CheckPhoneNumberExistsAsync(userForCreationDto.PhoneNumber))
            throw new InvalidOperationException($"Phone number {userForCreationDto.PhoneNumber} is already in use.");

        var user = new User
        {
            UserId = Guid.NewGuid(), 
            SkinTypeId = userForCreationDto.SkinTypeId,
            RoleId = userForCreationDto.RoleId,
            UserName = userForCreationDto.UserName,
            SurName = userForCreationDto.SurName,
            LastName = userForCreationDto.LastName,
            EmailAddress = userForCreationDto.EmailAddress,
            PhoneNumber = userForCreationDto.PhoneNumber,
            Status = userForCreationDto.Status,
            Password = userForCreationDto.Password,
            AvatarUrl = !string.IsNullOrWhiteSpace(userForCreationDto.AvatarUrl) ? userForCreationDto.AvatarUrl : null,
            CreatedBy = "System", 
            CreatedTime = DateTimeOffset.UtcNow,
            LastUpdatedBy = "System",
            LastUpdatedTime = DateTimeOffset.UtcNow,
            IsDeleted = false 
        };
        Console.WriteLine($"User before save: {JsonSerializer.Serialize(user)}");
        _unitOfWork.Users.Add(user);
        await _unitOfWork.SaveChangesAsync();

        // Manual mapping from User to UserDto
        var userDto = new UserDto
        {
            UserId = user.UserId,
            SkinTypeId = user.SkinTypeId,
            RoleId = user.RoleId,
            UserName = user.UserName,
            SurName = user.SurName,
            LastName = user.LastName,
            EmailAddress = user.EmailAddress,
            PhoneNumber = user.PhoneNumber,
            Status = user.Status,
            AvatarUrl = user.AvatarUrl,
            CreatedBy = user.CreatedBy,
            CreatedTime = user.CreatedTime,
            LastUpdatedBy = user.LastUpdatedBy,
            LastUpdatedTime = user.LastUpdatedTime,
            IsDeleted = user.IsDeleted
        };

        return userDto;
    }

    public async Task<UserDto> UpdateAsync(Guid userId, UserForUpdateDto userForUpdateDto)
    {
        if (userForUpdateDto == null)
            throw new ArgumentNullException(nameof(userForUpdateDto), "User data cannot be null.");

        var user = await _unitOfWork.Users.GetByIdAsync(userId);

        if (user == null || user.IsDeleted)
            throw new KeyNotFoundException($"User with ID {userId} not found.");
        
        // Check if the email already exists for another user
        if (await _unitOfWork.Users.GetQueryable().AnyAsync(u => u.EmailAddress == userForUpdateDto.EmailAddress && u.UserId != userId))
            throw new InvalidOperationException($"Email {userForUpdateDto.EmailAddress} is already in use.");

        // Check if the username already exists for another user
        if (await _unitOfWork.Users.GetQueryable().AnyAsync(u => u.UserName == userForUpdateDto.UserName && u.UserId != userId))
            throw new InvalidOperationException($"Username {userForUpdateDto.UserName} is already in use.");

        if (await _unitOfWork.Users.GetQueryable().AnyAsync(u => u.PhoneNumber == userForUpdateDto.PhoneNumber && u.UserId != userId))
            throw new InvalidOperationException($"Phone number {userForUpdateDto.PhoneNumber} is already in use.");
        user.LastUpdatedTime = DateTimeOffset.UtcNow;
        user.LastUpdatedBy = "System"; // Optionally replace with the current user if available

        _mapper.Map(userForUpdateDto, user);

        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync();

        return _mapper.Map<UserDto>(user);
    }

    public async Task DeleteAsync(Guid id)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(id);

        if (user == null || user.IsDeleted)
            throw new KeyNotFoundException($"User with ID {id} not found.");

        user.IsDeleted = true;
        user.DeletedTime = DateTimeOffset.UtcNow;
        user.DeletedBy = "System"; // Optionally replace with the current user if available

        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync();
    }

    public async Task<bool> CheckUserNameExistsAsync(string userName)
    {
        try
        {
            await GetByUserNameAsync(userName);
            return true;
        }
        catch (KeyNotFoundException)
        {
            return false;
        }
    }

    public async Task<bool> CheckEmailExistsAsync(string email)
    {
        try
        {
            await GetByEmailAsync(email);
            return true;
        }
        catch (KeyNotFoundException)
        {
            return false;
        }
    }
    
    public async Task<bool> CheckPhoneNumberExistsAsync(string phoneNumber)
    {
        return await _unitOfWork.Users.GetQueryable().AnyAsync(u => u.PhoneNumber == phoneNumber);
    }
}
