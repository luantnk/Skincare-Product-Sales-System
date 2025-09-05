using System;

namespace BusinessObjects.Models.Dto.Dashboard
{
    public class ProductProfitDto
    {
        public Guid ProductId { get; set; }
        public string ProductName { get; set; }
        public string ImageUrl { get; set; }       // Thumbnail image for the product
        public int QuantitySold { get; set; }
        public decimal GrossRevenue { get; set; }       // Revenue before discounts
        public decimal DiscountAmount { get; set; }     // Amount of discount applied
        public decimal Revenue { get; set; }            // Net revenue after discounts
        public decimal ProcurementCost { get; set; }    // Cost of goods sold
        public decimal Profit { get; set; }             // Revenue - ProcurementCost
        public decimal ProfitMargin { get; set; }       // Profit as percentage of Revenue
    }
}