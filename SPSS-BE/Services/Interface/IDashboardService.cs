﻿using BusinessObjects.Dto.Order;
using BusinessObjects.Models.Dto.Dashboard;
using Services.Response;

namespace Services.Interface;

public interface IDashboardService
{
    Task<PagedResponse<TotalRevenueDto>> GetTotalRevenueAsync(int pageNumber, int pageSize, DateTime? startDate = null, DateTime? endDate = null);
    Task<int> GetOrderCountAsync(DateTime? startDate = null, DateTime? endDate = null);
    // Task<List<RevenueTrendDto>> GetRevenueTrendAsync(DateTime startDate, DateTime endDate, string granularity = "daily");
    Task<PagedResponse<TopProductDto>> GetTopSellingProductsAsync(int pageNumber, int pageSize, DateTime? startDate = null, DateTime? endDate = null);
    Task<List<OrderStatusDistributionDto>> GetOrderStatusDistributionAsync(DateTime? startDate = null, DateTime? endDate = null);
    Task<PagedResponse<OrderDto>> GetTopPendingOrdersAsync(int topCount);
    
    // New methods for financial dashboard
    Task<FinancialSummaryDto> GetFinancialSummaryAsync(DateTime? startDate = null, DateTime? endDate = null);
    Task<PagedResponse<ProductProfitDto>> GetProductProfitAnalysisAsync(int pageNumber, int pageSize, DateTime? startDate = null, DateTime? endDate = null);
    Task<List<MonthlyFinancialReportDto>> GetMonthlyFinancialReportAsync(int year);
}