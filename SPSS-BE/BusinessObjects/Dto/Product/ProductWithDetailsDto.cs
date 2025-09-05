﻿using BusinessObjects.Dto.Brand;
using BusinessObjects.Dto.ProductCategory;
using BusinessObjects.Dto.ProductItem;
using BusinessObjects.Dto.SkinType;
using BusinessObjects.Models;
using BusinessObjects.Dto.Variation; // Thêm nếu cần

namespace BusinessObjects.Dto.Product
{
    public class ProductWithDetailsDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = null!;
        public string Description { get; set; } = null!;
        public int SoldCount { get; set; }
        public double Rating { get; set; }
        public decimal Price { get; set; }
        public decimal MarketPrice { get; set; }
        public string Status { get; set; } = null!;
        public string Thumbnail { get; set; } = null!;
        public List<SkinTypeForProductQueryDto> SkinTypes { get; set; } = new();
        public List<ProductItemDto> ProductItems { get; set; } = new();
        public BrandDto Brand { get; set; } = null!;
        public ProductCategoryDto Category { get; set; } = null!;
        public ProductSpecifications Specifications { get; set; } = new();

        // Thêm property này cho variations
        public List<VariationForProductEditDto> Variations { get; set; } = new();
    }
}