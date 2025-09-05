﻿using BusinessObjects.Dto.Blog;
using Microsoft.AspNetCore.Mvc;
using Services.Interface;
using Services.Response;
using System.ComponentModel.DataAnnotations;
using Services.Dto.Api;
using API.Extensions;
using BusinessObjects.Models;
using BusinessObjects.Dto.Account;

namespace API.Controllers;

[ApiController]
[Route("api/blogs")]
public class BlogController : ControllerBase
{
    private readonly IBlogService _blogService;

    public BlogController(IBlogService blogService)
    {
        _blogService = blogService ?? throw new ArgumentNullException(nameof(blogService));
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        try
        {
            var blog = await _blogService.GetByIdAsync(id);
            return Ok(ApiResponse<BlogWithDetailDto>.SuccessResponse(blog));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<BlogWithDetailDto>.FailureResponse(ex.Message));
        }
    }

    [HttpGet]
    public async Task<IActionResult> GetPaged([Range(1, int.MaxValue)] int pageNumber = 1, [Range(1, 100)] int pageSize = 10)
    {
        if (!ModelState.IsValid)
        {
            var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage).ToList();
            return BadRequest(ApiResponse<PagedResponse<BlogDto>>.FailureResponse("Invalid pagination parameters", errors));
        }

        var pagedBlogs = await _blogService.GetPagedAsync(pageNumber, pageSize);
        return Ok(ApiResponse<PagedResponse<BlogDto>>.SuccessResponse(pagedBlogs));
    }

    
   [CustomAuthorize("Staff")]
   [HttpPost]
   [ProducesResponseType(StatusCodes.Status201Created)]
   [ProducesResponseType(StatusCodes.Status400BadRequest)]
   public async Task<IActionResult> Create([FromBody] BlogForCreationDto blogDto)
   {
       if (!ModelState.IsValid)
       {
           var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage).ToList();
           return BadRequest(ApiResponse<BlogDto>.FailureResponse("Invalid blog data", errors));
       }
   
       try
       {
           var createdBlog = await _blogService.CreateBlogAsync(blogDto, new Guid("75786e5c-c310-4f8e-8c69-cd61c55d2d7b"));
           return Ok(ApiResponse<BlogDto>.SuccessResponse(createdBlog, "Blog created successfully"));
       }
       catch (Exception ex)
       {
           return BadRequest(ApiResponse<BlogDto>.FailureResponse(ex.Message));
       }
   }

   [CustomAuthorize("Staff")]
   [HttpPatch("{id:guid}")]
   [ProducesResponseType(StatusCodes.Status204NoContent)]
   [ProducesResponseType(StatusCodes.Status400BadRequest)]
   [ProducesResponseType(StatusCodes.Status404NotFound)]
   public async Task<IActionResult> Update(Guid id, [FromBody] BlogForUpdateDto blogDto)
   {
       if (!ModelState.IsValid)
       {
           var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage).ToList();
           return BadRequest(ApiResponse<BlogDto>.FailureResponse("Invalid blog data", errors));
       }

       try
       {
           Guid? userId = HttpContext.Items["UserId"] as Guid?;
           if (userId == null)
           {
               return BadRequest(ApiResponse<AccountDto>.FailureResponse("User ID is missing or invalid"));
           }
           return Ok(ApiResponse<BlogDto>.SuccessResponse(
               await _blogService.UpdateBlogAsync(id, blogDto, userId.Value), "Blog updated successfully"));
       }
       catch (KeyNotFoundException ex)
       {
           return NotFound(ApiResponse<BlogDto>.FailureResponse(ex.Message));
       }
       catch (Exception ex)
       {
           return BadRequest(ApiResponse<BlogDto>.FailureResponse(ex.Message));
       }
   }

    [CustomAuthorize("Staff")]
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid id)
    {
        try
        {
            // Guid? userId = HttpContext.Items["UserId"] as Guid?;
            // if (userId == null)
            // {
            //     return BadRequest(ApiResponse<AccountDto>.FailureResponse("User ID is missing or invalid"));
            // }
            return Ok(ApiResponse<bool>.SuccessResponse(
            await _blogService.DeleteAsync(id, new Guid("75786e5c-c310-4f8e-8c69-cd61c55d2d7b")), "Blog deleted successfully"));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<BlogDto>.FailureResponse(ex.Message));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiResponse<BlogDto>.FailureResponse(ex.Message));
        }
    }
}
