import { createSlice } from "@reduxjs/toolkit";
import { getAllBrands, addBrand, updateBrand, deleteBrand } from "./thunk";

interface BrandState {
  loading: boolean;
  error: string | null;
  brands: {
    data: {
      items: any[];
      totalCount: number;
      pageNumber: number;
      pageSize: number;
      totalPages: number;
    }
  };
}

export const initialState: BrandState = {
  loading: false,
  error: null,
  brands: {
    data: {
      items: [],
      totalCount: 0,
      pageNumber: 1,
      pageSize: 5,
      totalPages: 1
    }
  },
};

const brandSlice = createSlice({
  name: "brand",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    // Get Brands
    builder.addCase(getAllBrands.pending, (state) => {
      state.loading = true;
      state.error = null;
    });
    builder.addCase(getAllBrands.fulfilled, (state, action) => {
      state.loading = false;
      state.brands = {
        data: action.payload.data
      };
      state.error = null;
    });
    builder.addCase(getAllBrands.rejected, (state, action) => {
      state.loading = false;
      state.error = action.error.message || null;
    });

    // Add Brand
    builder.addCase(addBrand.pending, (state) => {
      state.loading = true;
      state.error = null;
    });
    builder.addCase(addBrand.fulfilled, (state, action) => {
      state.loading = false;
      state.brands.data.items.unshift(action.payload.data);
      state.error = null;
    });
    builder.addCase(addBrand.rejected, (state, action) => {
      state.loading = false;
      state.error = action.error.message || null;
    });

    // Update Brand
    builder.addCase(updateBrand.pending, (state) => {
      state.loading = true;
      state.error = null;
    });
    builder.addCase(updateBrand.fulfilled, (state, action) => {
      state.loading = false;
      state.brands.data.items = state.brands.data.items.map(brand =>
        brand.id === action.payload.data.id ? action.payload.data : brand
      );
      state.error = null;
    });
    builder.addCase(updateBrand.rejected, (state, action) => {
      state.loading = false;
      state.error = action.error.message || null;
    });

    // Delete Brand
    builder.addCase(deleteBrand.pending, (state) => {
      state.loading = true;
      state.error = null;
    });
    builder.addCase(deleteBrand.fulfilled, (state, action) => {
      state.loading = false;
      state.brands.data.items = state.brands.data.items.filter(
        brand => brand.id !== action.payload.data
      );
      state.error = null;
    });
    builder.addCase(deleteBrand.rejected, (state, action) => {
      state.loading = false;
      state.error = action.error.message || null;
    });
  },
});

export default brandSlice.reducer; 