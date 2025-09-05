﻿using BusinessObjects.Dto.Account;
using BusinessObjects.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Repositories.Interface;
using Services.Interface;
using System;
using System.Threading.Tasks;

namespace Services.Implementation
{
    public class AccountService : IAccountService
    {
        private readonly IUnitOfWork _unitOfWork;

        public AccountService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork ?? throw new ArgumentNullException(nameof(unitOfWork));
        }

        public async Task<AccountDto> GetAccountInfoAsync(Guid userId)
        {
            // Lấy thông tin người dùng từ database
            var user = await _unitOfWork.Users
                .GetQueryable()
                .Include(u => u.SkinType)
                .FirstOrDefaultAsync(u => u.UserId == userId && !u.IsDeleted);

            if (user == null)
                throw new KeyNotFoundException($"Không tìm thấy người dùng với ID {userId}.");

            // Chuyển đổi dữ liệu từ User entity sang AccountDto
            return new AccountDto
            {
                UserId = user.UserId,
                SkinType = user.SkinType?.Name,
                UserName = user.UserName,
                SurName = user.SurName,
                LastName = user.LastName,
                EmailAddress = user.EmailAddress,
                PhoneNumber = user.PhoneNumber,
                AvatarUrl = user.AvatarUrl,
                CreatedTime = user.CreatedTime
            };
        }

        public async Task<IList<string>> MigrateToFirebaseLinkList(List<IFormFile> files)
        {
            var uploadImageService = new ManageFirebaseImage.ManageFirebaseImageService();
            List<string> downloadUrl = [];
            foreach (var file in files)
            {
                if (file.Length == 0)
                {
                    throw new Exception("File is empty");
                }

                using (var stream = file.OpenReadStream())
                {
                    var fileName = $"{Guid.NewGuid()}_{file.FileName}";
                    var imageUrl = await uploadImageService.UploadFileAsync(stream, fileName);
                    downloadUrl.Add(imageUrl);
                }
            }
            return downloadUrl;

        }

        public async Task<string> UpdateAvatarAsync(Guid userId, IFormFile avatarFile)
        {
            if (avatarFile == null || avatarFile.Length == 0)
            {
                throw new ArgumentException("Avatar file cannot be null or empty.", nameof(avatarFile));
            }

            // Lấy thông tin người dùng từ database
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null)
            {
                throw new KeyNotFoundException($"Không tìm thấy người dùng với ID {userId}.");
            }

            // Gọi hàm MigrateToFirebaseLinkList để upload file và lấy URL
            var avatarUrls = await MigrateToFirebaseLinkList(new List<IFormFile> { avatarFile });
            var avatarUrl = avatarUrls.FirstOrDefault();

            if (string.IsNullOrEmpty(avatarUrl))
            {
                throw new Exception("Failed to upload avatar and retrieve URL.");
            }

            // Cập nhật URL avatar cho người dùng
            user.AvatarUrl = avatarUrl;
            user.LastUpdatedBy = userId.ToString();
            user.LastUpdatedTime = DateTimeOffset.UtcNow;

            // Lưu thay đổi vào database
            _unitOfWork.Users.Update(user);
            await _unitOfWork.SaveChangesAsync();

            // Trả về URL avatar mới
            return avatarUrl;
        }

        public async Task<bool> DeleteFirebaseLink(string imageUrl)
        {

            var deleteImageService = new ManageFirebaseImage.ManageFirebaseImageService();
            await deleteImageService.DeleteFileAsync(imageUrl);

            return true;
        }

        public async Task<AccountDto> UpdateAccountInfoAsync(Guid userId, AccountForUpdateDto accountUpdateDto)
        {
            if (accountUpdateDto == null)
                throw new ArgumentNullException(nameof(accountUpdateDto), "Thông tin cập nhật không được để trống.");

            // Lấy thông tin người dùng từ database
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null)
                throw new KeyNotFoundException($"Không tìm thấy người dùng với ID {userId}.");

            // Cập nhật các thông tin người dùng từ AccountForUpdateDto
            user.UserName = accountUpdateDto.UserName ?? user.UserName;
            user.SurName = accountUpdateDto.SurName ?? user.SurName;
            user.LastName = accountUpdateDto.LastName ?? user.LastName;
            user.EmailAddress = accountUpdateDto.EmailAddress ?? user.EmailAddress;
            user.PhoneNumber = accountUpdateDto.PhoneNumber ?? user.PhoneNumber;
            user.LastUpdatedBy = userId.ToString();
            user.LastUpdatedTime = DateTimeOffset.UtcNow;

            // Lưu các thay đổi
            _unitOfWork.Users.Update(user);
            await _unitOfWork.SaveChangesAsync();

            // Trả về dữ liệu cập nhật
            return new AccountDto
            {
                UserId = user.UserId,
                UserName = user.UserName,
                SurName = user.SurName,
                LastName = user.LastName,
                EmailAddress = user.EmailAddress,
                PhoneNumber = user.PhoneNumber,
                CreatedTime = user.CreatedTime
            };
        }
    }
}
