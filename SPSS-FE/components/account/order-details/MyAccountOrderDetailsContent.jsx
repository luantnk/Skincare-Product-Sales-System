"use client";
import React, { useState, useEffect } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import request from "@/utils/axios";
import { useThemeColors } from "@/context/ThemeContext";
import { CircularProgress, Button } from "@mui/material";
import Link from "next/link";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import useAuthStore from "@/context/authStore";
import dayjs from "dayjs";
import toast from "react-hot-toast";

// Import các component đã tách
import OrderStatusTracker from "./OrderStatusTracker";
import OrderInfoCards from "./OrderInfoCards";
import OrderProductList from "./OrderProductList";
import ActionButtons from "./ActionButtons";
import OrderDialogs from "./OrderDialogs";
import BankPaymentModal from "@/components/payment/BankPaymentModal";

// Import các utility function
import { 
  getStatusColor, 
  getStatusInfo, 
  getStatusIcon, 
  getStatusCircleColor, 
  getStatusBorderColor, 
  isStatusBefore,
  translateStatus
} from "./StatusUtils";

export default function MyAccountOrderDetailsContent() {
  const [order, setOrder] = useState(null);
  const [loading, setLoading] = useState(true);
  const [openCancelDialog, setOpenCancelDialog] = useState(false);
  const searchParams = useSearchParams();
  const orderId = searchParams.get("id");
  const userIdFromUrl = searchParams.get("userId");
  const mainColor = useThemeColors();
  const [reasons, setReasons] = useState([]);
  const [reason, setReason] = useState();
  const [selectedReason, setCancelReason] = useState("");
  const router = useRouter();
  const { Id, isLoggedIn } = useAuthStore();
  const [reviewModalOpen, setReviewModalOpen] = useState(false);
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [paymentMethods, setPaymentMethods] = useState([]);
  const [openPaymentDialog, setOpenPaymentDialog] = useState(false);
  const [selectedPaymentMethod, setSelectedPaymentMethod] = useState("");
  const [paymentMethodError, setPaymentMethodError] = useState("");
  const [updatingPayment, setUpdatingPayment] = useState(false);
  const [openBankModal, setOpenBankModal] = useState(false);
  const [qrImageUrl, setQrImageUrl] = useState("");
  const [orderBankModal, setOrderBankModal] = useState(null);

  useEffect(() => {
    if (!isLoggedIn) {
      toast.error("Bạn cần đăng nhập để xem chi tiết đơn hàng");
      router.push("/login");
      return;
    }

    if (orderId) {
      fetchOrderDetails();
      fetchPaymentMethods();
    }
  }, [orderId, isLoggedIn]);

  useEffect(() => {
    if (order?.cancelReasonId) {
      request.get(`/cancel-reasons/${order.cancelReasonId}`).then(({ data }) => {
        setReason(data.data.description);
      });
    }
  }, [order]);

  useEffect(() => {
    request.get("/cancel-reasons").then(({ data }) => {
      setReasons(data.data.items);
    });
  }, []);

  const fetchPaymentMethods = async () => {
    try {
      const response = await request.get("/payment-methods");
      if (response.data && response.data.data) {
        setPaymentMethods(response.data.data.items || []);
        if (order && order.paymentMethodId) {
          setSelectedPaymentMethod(order.paymentMethodId);
        }
      }
    } catch (error) {
      console.error("Error fetching payment methods:", error);
      toast.error("Không thể lấy danh sách phương thức thanh toán");
    }
  };

  const fetchOrderDetails = async () => {
    try {
      setLoading(true);
      const response = await request.get(`/orders/${orderId}`);
      
      // Cập nhật order
      setOrder(response.data.data);
      
      // Cập nhật phương thức thanh toán đã chọn
      if (response.data.data.paymentMethodId) {
        setSelectedPaymentMethod(response.data.data.paymentMethodId);
      }
      
      // Tải thông tin payment method nếu cần
      if (paymentMethods.length === 0) {
        await fetchPaymentMethods();
      }
    } catch (error) {
      console.error("Error fetching order details:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleUpdatePaymentMethod = async () => {
    if (!selectedPaymentMethod) {
      setPaymentMethodError("Vui lòng chọn phương thức thanh toán");
      return;
    }

    try {
      setUpdatingPayment(true);
      const response = await request.patch(
        `/orders/${order.id}/payment-method?paymentMethodId=${selectedPaymentMethod}`
      );
      
      if (response.status === 200) {
        toast.success("Cập nhật phương thức thanh toán thành công");
        setOpenPaymentDialog(false);
        fetchOrderDetails();
      }
    } catch (error) {
      console.error("Error updating payment method:", error);
      toast.error("Không thể cập nhật phương thức thanh toán");
    } finally {
      setUpdatingPayment(false);
    }
  };

  const getPaymentMethodName = (paymentMethodId) => {
    if (!paymentMethodId) return "Chưa xác định";
    const method = paymentMethods.find(m => m.id === paymentMethodId);
    return method ? method.paymentType : "Chưa xác định";
  };

  const getPaymentMethodImage = (paymentMethodId) => {
    if (!paymentMethodId) return "";
    const method = paymentMethods.find(m => m.id === paymentMethodId);
    return method?.imageUrl || "";
  };

  const handlePayNow = async () => {
    try {
      const method = paymentMethods.find(m => m.id === order.paymentMethodId);
      
      const effectiveUserId = Id || userIdFromUrl;
      
      if (!effectiveUserId) {
        toast.error("Bạn cần đăng nhập để thực hiện thanh toán");
        router.push("/login");
        return;
      }
      
      if (method && method.paymentType === "VNPAY") {
        const vnpayRes = await request.get(
          `/VNPAY/get-transaction-status-vnpay?orderId=${order.id}&userId=${effectiveUserId}&urlReturn=https%3A%2F%2Fspssapi-hxfzbchrcafgd2hg.southeastasia-01.azurewebsites.net`
        );
        
        if (vnpayRes.status === 200) {
          window.location.href = vnpayRes.data.data;
        } else {
          toast.error("Không thể khởi tạo thanh toán");
        }
      } else if (method && method.paymentType === "BANK") {
        const bankId = "970422";
        const accountNo = "0352314340";
        const template = "print";
        const amount = (order.discountedOrderTotal ?? order.orderTotal)?.toFixed(0) || (order.discountedOrderTotal ?? order.orderTotal);
        const description = encodeURIComponent(order.id);
        const accountName = encodeURIComponent("DANG HO TUAN CUONG");
        const qrUrl = `https://img.vietqr.io/image/${bankId}-${accountNo}-${template}.png?amount=${amount}&addInfo=${description}&accountName=${accountName}`;
        setOrderBankModal(order);
        setQrImageUrl(qrUrl);
        setOpenBankModal(true);
      } else {
        toast.info(`Đã chọn thanh toán qua ${method?.paymentType || "phương thức không xác định"}`);
      }
    } catch (error) {
      console.error("Payment error:", error);
      toast.error("Không thể thực hiện thanh toán, vui lòng thử lại sau");
    }
  };

  const handleCancelOrder = async () => {
    try {
      await request.patch(`/orders/${order.id}/status?newStatus=Cancelled&cancelReasonId=${selectedReason}`);
      setOpenCancelDialog(false);
      fetchOrderDetails();
    } catch (error) {
      console.error("Error cancelling order:", error);
      setOpenCancelDialog(false);
    }
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat("vi-VN", {
      style: "currency",
      currency: "VND",
    }).format(amount);
  };

  const handleOpenReviewModal = (product) => {
    setSelectedProduct(product);
    setReviewModalOpen(true);
  };

  const handleCloseReviewModal = () => {
    setReviewModalOpen(false);
    setSelectedProduct(null);
  };

  const handleOpenCancelDialog = () => {
    setOpenCancelDialog(true);
  };

  const handleCloseCancelDialog = () => {
    setOpenCancelDialog(false);
  };

  const handleOpenPaymentDialog = () => {
    setOpenPaymentDialog(true);
  };

  const handleClosePaymentDialog = () => {
    setOpenPaymentDialog(false);
  };

  useEffect(() => {
    if (!openBankModal || !orderBankModal?.id) return;
    const timer = setInterval(async () => {
      try {
        const resp = await request.get(`/orders/${orderBankModal.id}`);
        const status = resp.data.data?.status || resp.data.status;
        if (status && status.toLowerCase().trim() === "processing") {
          setOpenBankModal(false);
          window.location.href = `/payment-success?id=${orderBankModal.id}`;
        }
      } catch {}
    }, 4000);
    return () => clearInterval(timer);
  }, [openBankModal, orderBankModal]);

  if (loading) {
    return (
      <div className="flex justify-center items-center py-8">
        <CircularProgress sx={{ color: mainColor }} />
      </div>
    );
  }

  if (!order) {
    return <div className="text-center py-8">Order not found</div>;
  }

  const { currentStep, lastValidStep } = getStatusInfo(order.status, order);

  return (
    <div className="account-order-details my-account-content">
      <div className="flex justify-end py-2">
        <Button
          variant="outlined"
          startIcon={<ArrowBackIcon />}
          href="/orders"
          size="small"
          sx={{
            borderColor: mainColor,
            color: mainColor,
            fontFamily: '"Roboto", sans-serif',
            "&:hover": {
              borderColor: mainColor,
              backgroundColor: `${mainColor}10`,
            },
          }}
        >
          Quay Lại Danh Sách
        </Button>
      </div>

      <div className="bg-white p-4 rounded-lg shadow-sm mb-4">
        <div className="flex justify-between items-start mb-4">
          <div>
            <h3 className="text-base font-medium mb-1">
              Đơn Hàng #{order.id.substring(0, 8)}
            </h3>
            <p className="text-gray-500 text-sm">
              {dayjs(order.createdTime).format("DD/MM/YYYY")} •{" "}
              {order.orderDetails.length} Sản phẩm
            </p>
          </div>
          <span
            className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(
              order.status
            )}`}
          >
            {order.status}
          </span>
        </div>

        <OrderStatusTracker 
          order={order}
          currentStep={currentStep}
          lastValidStep={lastValidStep}
          getStatusCircleColor={getStatusCircleColor}
          getStatusBorderColor={getStatusBorderColor}
          getStatusIcon={getStatusIcon}
          translateStatus={translateStatus}
          reason={reason}
          isStatusBefore={isStatusBefore}
        />

        <OrderInfoCards 
          order={order}
          formatCurrency={formatCurrency}
          mainColor={mainColor}
          getPaymentMethodName={getPaymentMethodName}
          getPaymentMethodImage={getPaymentMethodImage}
          handleOpenPaymentDialog={handleOpenPaymentDialog}
        />

        <OrderProductList 
          order={order}
          formatCurrency={formatCurrency}
          mainColor={mainColor}
          handleOpenReviewModal={handleOpenReviewModal}
        />

        <ActionButtons 
          order={order}
          mainColor={mainColor}
          handleOpenCancelDialog={handleOpenCancelDialog}
          handleOpenPaymentDialog={handleOpenPaymentDialog}
          handlePayNow={handlePayNow}
          paymentMethods={paymentMethods}
          paymentMethodId={order?.paymentMethodId}
        />
      </div>

      <OrderDialogs 
        openCancelDialog={openCancelDialog}
        handleCloseCancelDialog={handleCloseCancelDialog}
        selectedReason={selectedReason}
        setCancelReason={setCancelReason}
        reasons={reasons}
        handleCancelOrder={handleCancelOrder}
        mainColor={mainColor}
        
        reviewModalOpen={reviewModalOpen}
        handleCloseReviewModal={handleCloseReviewModal}
        selectedProduct={selectedProduct}
        order={order}
        fetchOrderDetails={fetchOrderDetails}
        
        openPaymentDialog={openPaymentDialog}
        handleClosePaymentDialog={handleClosePaymentDialog}
        selectedPaymentMethod={selectedPaymentMethod}
        setSelectedPaymentMethod={setSelectedPaymentMethod}
        paymentMethodError={paymentMethodError}
        setPaymentMethodError={setPaymentMethodError}
        paymentMethods={paymentMethods}
        updatingPayment={updatingPayment}
        handleUpdatePaymentMethod={handleUpdatePaymentMethod}
      />
      <BankPaymentModal
        open={openBankModal}
        onClose={() => setOpenBankModal(false)}
        order={orderBankModal}
        qrImageUrl={qrImageUrl}
      />
    </div>
  );
} 