﻿using Microsoft.AspNetCore.Mvc;
using Services.Interface;
using System.ComponentModel.DataAnnotations;
using System.Threading.Tasks;
using BusinessObjects.Dto.CancelReason;
using Services.Dto.Api;
using Services.Response;
using API.Extensions;
using BusinessObjects.Dto.Account;

namespace API.Controllers;

[ApiController]
[Route("api/cancel-reasons")]
public class CancelReasonController : ControllerBase
{
    private readonly ICancelReasonService _cancelReasonService;

    public CancelReasonController(ICancelReasonService cancelReasonService) => _cancelReasonService = cancelReasonService ?? throw new ArgumentNullException(nameof(cancelReasonService));

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        try
        {
            var cancelReason = await _cancelReasonService.GetByIdAsync(id);
            return Ok(ApiResponse<CancelReasonDto>.SuccessResponse(cancelReason));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<CancelReasonDto>.FailureResponse(ex.Message));
        }
    }

    [HttpGet]
    public async Task<IActionResult> GetPaged(
        [Range(1, int.MaxValue)] int pageNumber = 1,
        [Range(1, 100)] int pageSize = 10)
    {
        if (!ModelState.IsValid)
        {
            var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage).ToList();
            return BadRequest(ApiResponse<PagedResponse<CancelReasonDto>>.FailureResponse("Invalid pagination parameters", errors));
        }

        var pagedData = await _cancelReasonService.GetPagedAsync(pageNumber, pageSize);
        return Ok(ApiResponse<PagedResponse<CancelReasonDto>>.SuccessResponse(pagedData));
    }

    [CustomAuthorize("Manager")]
    [HttpPost]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create([FromBody] CancelReasonForCreationDto cancelReasonDto)
    {
        if (!ModelState.IsValid)
        {
            var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage).ToList();
            return BadRequest(ApiResponse<CancelReasonDto>.FailureResponse("Invalid cancel reason data", errors));
        }
        Guid? userId = HttpContext.Items["UserId"] as Guid?;
        if (userId == null)
        {
            return BadRequest(ApiResponse<AccountDto>.FailureResponse("User ID is missing or invalid"));
        }
        try
        {
            var createdCancelReason = await _cancelReasonService.CreateAsync(cancelReasonDto, userId.Value);
            var response = ApiResponse<CancelReasonDto>.SuccessResponse(createdCancelReason, "Cancel reason created successfully");
            return CreatedAtAction(nameof(GetById), new { id = createdCancelReason.Id }, response);
        }
        catch (ArgumentNullException ex)
        {
            return BadRequest(ApiResponse<CancelReasonDto>.FailureResponse(ex.Message));
        }
    }

    [CustomAuthorize("Manager")]
    [HttpPatch("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(Guid id, [FromBody] CancelReasonForUpdateDto cancelReasonDto)
    {
        if (!ModelState.IsValid)
        {
            var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage).ToList();
            return BadRequest(ApiResponse<CancelReasonDto>.FailureResponse("Invalid cancel reason data", errors));
        }
        Guid? userId = HttpContext.Items["UserId"] as Guid?;
        if (userId == null)
        {
            return BadRequest(ApiResponse<AccountDto>.FailureResponse("User ID is missing or invalid"));
        }
        try
        {
            var updatedCancelReason = await _cancelReasonService.UpdateAsync(id, cancelReasonDto, userId.Value);
            return Ok(ApiResponse<CancelReasonDto>.SuccessResponse(updatedCancelReason, "Cancel reason updated successfully"));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<CancelReasonDto>.FailureResponse(ex.Message));
        }
        catch (ArgumentNullException ex)
        {
            return BadRequest(ApiResponse<CancelReasonDto>.FailureResponse(ex.Message));
        }
    }

    [CustomAuthorize("Manager")]
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid id)
    {
        try
        {
            Guid? userId = HttpContext.Items["UserId"] as Guid?;
            if (userId == null)
            {
                return BadRequest(ApiResponse<AccountDto>.FailureResponse("User ID is missing or invalid"));
            }
            await _cancelReasonService.DeleteAsync(id, userId.Value);
            return Ok(ApiResponse<object>.SuccessResponse(null, "Cancel reason deleted successfully"));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.FailureResponse(ex.Message));
        }
    }
}