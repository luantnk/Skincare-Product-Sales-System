"use client";
import { Suspense } from "react";

const ProductsLoading = () => (
  <div className="container text-center py-8">
    <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary mx-auto"></div>
    <div className="mt-4">Đang tải sản phẩm...</div>
  </div>
);

export default function ProductLayout({ children }) {
  return (
    <Suspense fallback={<ProductsLoading />}>
      {children}
    </Suspense>
  );
} 