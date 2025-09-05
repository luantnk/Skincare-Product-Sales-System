using System;

namespace BusinessObjects.Models.Dto.Dashboard
{
    public class FinancialSummaryDto
    {
        public decimal GrossRevenue { get; set; }         // Total revenue before voucher discounts
        public decimal DiscountAmount { get; set; }       // Total amount of discounts from vouchers

        public decimal TotalRevenue { get; set; }         // Net revenue after discounts
        public decimal TotalProcurementCost { get; set; }
        public decimal InventoryProcurementCost { get; set; }
        public decimal TotalProfit { get; set; }
        public decimal ProfitMargin { get; set; }
        public int CompletedOrderCount { get; set; }
        public int PendingOrderCount { get; set; }
        public double ProfitMarginPercent { get; set; }
        public double ProcurementCostPercent { get; set; }
        public double InventoryCostPercent { get; set; }
        public double CompletedOrderRate { get; set; }
        public double PendingOrderRate { get; set; }
        public double DiscountRate { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        
        // New attributes requested
        public int TotalUsers { get; set; }             // Total number of users on the website
        public int TotalOrders { get; set; }            // Total number of orders in the system
        public int TotalDeliveredOrders { get; set; }   // Total number of delivered orders
    }
}