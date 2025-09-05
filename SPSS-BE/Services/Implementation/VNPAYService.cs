using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using BusinessObjects.Dto.VNPay;
using BusinessObjects.Models;
using Microsoft.EntityFrameworkCore;
using Repositories.Interface;
using Services.Interface;

namespace Services.Implementation;

public class VNPAYService : IVNPayService
{
    private readonly IOrderService _orderService;
    private readonly IUnitOfWork _unitOfWork;

    
    public VNPAYService(IUnitOfWork unitOfWork, IOrderService orderService)
        {
            _unitOfWork = unitOfWork;
            _orderService = orderService;
        }

        public string vnp_Url = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";
        public string vnp_ReturnUrl = "/api/VNPAY/vnpay-payment";
        public string vnp_TmnCode = "99EBBM2U";
        public string vnp_HashSecret = "HMYDH7PAL07DLX77WG37DY5I0VIJEJIB";
        public string vnp_apiUrl = "https://sandbox.vnpayment.vn/merchant_webapi/api/transaction";
        public string vnp_Version = "2.1.0";
        public string vnp_Command = "pay";  
        public string vnp_IpAddr = "127.0.0.1";
        public string orderType = "other";



        public async Task<string> GetTransactionStatusVNPay(Guid orderId, Guid userId, String urlReturn)
        {
            var order = await _unitOfWork.Orders.Entities
                .Where(o => o.Id == orderId).FirstOrDefaultAsync();

            if (order == null || order.UserId != userId)
            {
                throw new KeyNotFoundException($"Order with ID {orderId} is processing.");
            }

            if (order.Status == "Processing")
            {
                throw new KeyNotFoundException($"Order with ID {orderId} is already paid.");
            }

            string vnp_TxnRef = GetRandomNumber(8);
            int? money = (int)order.OrderTotal * 100;
            string totalPrice = money.ToString() ?? "000";

            Dictionary<string, string> vnp_Params = new();
            vnp_Params.Add("vnp_Version", vnp_Version);
            vnp_Params.Add("vnp_Command", vnp_Command);
            vnp_Params.Add("vnp_TmnCode", vnp_TmnCode);
            vnp_Params.Add("vnp_Amount", totalPrice);
            vnp_Params.Add("vnp_CurrCode", "VND");

            vnp_Params.Add("vnp_TxnRef", vnp_TxnRef);
            vnp_Params.Add("vnp_OrderInfo", order.Id.ToString());
            vnp_Params.Add("vnp_OrderType", orderType);

            string locate = "vn";
            vnp_Params.Add("vnp_Locale", locate);

            urlReturn += vnp_ReturnUrl;
            vnp_Params.Add("vnp_ReturnUrl", urlReturn);
            vnp_Params.Add("vnp_IpAddr", vnp_IpAddr);


            var formatter = "yyyyMMddHHmmss";
            var now = DateTime.UtcNow.AddHours(7); 
            var vnp_CreateDate = now.ToString(formatter, CultureInfo.InvariantCulture);
            vnp_Params["vnp_CreateDate"] = vnp_CreateDate;

            var expireTime = now.AddMinutes(15); 
            var vnp_ExpireDate = expireTime.ToString(formatter, CultureInfo.InvariantCulture);
            vnp_Params["vnp_ExpireDate"] = vnp_ExpireDate;

            var fieldNames = vnp_Params.Keys.ToList();
            fieldNames.Sort();

            var hashData = new StringBuilder();
            var query = new StringBuilder();

           

            foreach (var fieldName in fieldNames)
            {
                var fieldValue = vnp_Params[fieldName];
                if (!(fieldValue == null))
                {
                    hashData.Append(Uri.EscapeDataString(fieldName))
                            .Append('=')
                            .Append(Uri.EscapeDataString(fieldValue));
                    query.Append(Uri.EscapeDataString(fieldName))
                         .Append('=')
                         .Append(Uri.EscapeDataString(fieldValue));
                    if (fieldNames.IndexOf(fieldName) != fieldNames.Count - 1)
                    {
                        query.Append('&');
                        hashData.Append('&');
                    }
                }
            }

            var queryUrl = query.ToString();
            var vnp_SecureHash = HmacSHA512(vnp_HashSecret, hashData.ToString());
            queryUrl += "&vnp_SecureHash=" + vnp_SecureHash;

        
            order.Status = "Awaiting Payment";
            order.PaymentMethodId = Guid.Parse("354EDA95-5BE5-41BE-ACC3-CFD70188118A");

            _unitOfWork.Orders.Update(order);
            await _unitOfWork.SaveChangesAsync();
            // var updateDto = new UpdateStatusOrderDto
            // {
            //     OrderId = orderId,
            //     Status = "Awaiting Payment"
            // };
            //
            //
            // await _orderService.UpdateOrderStatusAsync(order.UserId.ToString(), updateDto);

            return vnp_Url + "?" + queryUrl;
        }
        

        public async Task<VNPAYResponse> VNPAYPayment(VNPAYRequest request)
        {
            VNPAYResponse response = new();

            var fields = new Dictionary<string, string>();

            var totalPrice = request.VnpAmount;
            var bankCode = request.VnpBankCode;
            var bankTranNo = request.VnpBankTranNo;
            var cardType = request.VnpCardType;
            var orderInfo = request.VnpOrderInfo;
            var payDate = request.VnpPayDate;
            var responseCode = request.VnpResponseCode;
            var tmnCode = request.VnpTmnCode;
            var transactionNo = request.VnpTransactionNo;
            var transactionStatus = request.VnpTransactionStatus;
            var vnpSecureHash = request.VnpSecureHash;
            var tnxRef = request.VnpTxnRef;
            

            var order = await _unitOfWork.Orders.Entities
              .Where(o => o.Id.ToString() == orderInfo).FirstOrDefaultAsync();
            
            if (order == null)
            // await _unitOfWork.SaveChangesAsync();
            //
            // var updateDto = new UpdateStatusOrderDto
            // {
            //     OrderId = order.Id,
            //     Status = "Payment Failed"
            // };

            if (response == null) {

                response = new VNPAYResponse
                {
                    IsSucceed = false,
                    Text = "Payment approve failed"
                };
                return response;
            }


            if (totalPrice == null || !double.TryParse(totalPrice, out _))
            {
                response.IsSucceed = false;
                response.Text = "Order price not found";
                return response;
            }

            if (orderInfo == null)
            {
                response.IsSucceed = false;
                response.Text = "Order not found";
            }

            var amount = double.Parse(totalPrice) / 100;
        //var returnUrl = $"http://localhost:3000/payment-success?id={orderInfo}";
            var returnUrl = "";





        fields.Add("vnp_Amount", totalPrice ?? string.Empty);
            fields.Add("vnp_BankCode", bankCode ?? string.Empty);
            fields.Add("vnp_BankTranNo", bankTranNo ?? string.Empty);
            fields.Add("vnp_CardType", cardType ?? string.Empty);
            fields.Add("vnp_OrderInfo", orderInfo ?? string.Empty);
            fields.Add("vnp_PayDate", payDate ?? string.Empty);
            fields.Add("vnp_ResponseCode", responseCode ?? string.Empty);
            fields.Add("vnp_TmnCode", tmnCode ?? string.Empty);
            fields.Add("vnp_TransactionNo", transactionNo ?? string.Empty);
            fields.Add("vnp_TransactionStatus", transactionStatus ?? string.Empty);
            fields.Add("vnp_TxnRef", tnxRef ?? string.Empty);



            var signValue = HashAllFields(fields);
            Console.WriteLine($"Generated Sign: {signValue}");
            Console.WriteLine($"Received vnp_SecureHash: {vnpSecureHash}");
            if (signValue.Equals(vnpSecureHash))
            {
                if ("00".Equals(request.VnpTransactionStatus))
                {
                    order.Status = "Processing";
                    order.PaymentMethodId = Guid.Parse("354EDA95-5BE5-41BE-ACC3-CFD70188118A");

                    _unitOfWork.Orders.Update(order);
                    await _unitOfWork.SaveChangesAsync();
                var statusChange = await _unitOfWork.StatusChanges.FirstOrDefaultAsync(sc => sc.OrderId == order.Id);

                if (statusChange != null)
                {
                    statusChange.Status = "Processing"; 
                    statusChange.Date = DateTimeOffset.UtcNow; 
                    _unitOfWork.StatusChanges.Update(statusChange);
                }

                await _unitOfWork.SaveChangesAsync();

                returnUrl = $"https://spss-fe-tuannguyen333s-projects.vercel.app/payment-success?id={orderInfo}";


                // updateDto = new UpdateStatusOrderDto
                // {
                //     OrderId = order.Id,
                //     Status = "Processing"
                // };
                //
                // await _orderService.UpdateOrderStatusAsync(order.UserId.ToString(), updateDto);

                // var statusChangeDto = new StatusChangeForCreationDto
                // {
                //     OrderId = order.Id,
                //     Status = "Processing"
                // };
                // await _statusChangeService.Create(statusChangeDto, order.UserId.ToString());
                }

                else
                {
                    order.Status = "Payment Failed";
                    order.PaymentMethodId = Guid.Parse("354EDA95-5BE5-41BE-ACC3-CFD70188118A");

                    _unitOfWork.Orders.Update(order);
                    await _unitOfWork.SaveChangesAsync();
                    returnUrl = $"https://spss-fe-tuannguyen333s-projects.vercel.app/payment-failure?id={orderInfo}";

                // updateDto = new UpdateStatusOrderDto
                // {
                //     OrderId = order.Id,
                //     Status = "Payment Failed"
                // };
                //
                // await _orderService.UpdateOrderStatusAsync(order.UserId.ToString(), updateDto);

                // // Create a new status change record after updating the order status
                // var statusChangeDto = new StatusChangeForCreationDto
                // {
                //     OrderId = order.Id,
                //     Status = order.Status
                // };
                //
                // await _statusChangeService.Create(statusChangeDto, order.UserId.ToString());
                // await _unitOfWork.SaveAsync();

                // // Retrieve the order details to update product stock
                // var orderDetailRepository = _unitOfWork.GetRepository<OrderDetail>();
                // var orderDetails = await orderDetailRepository.Entities
                //     .Where(od => od.OrderId == order.Id)
                //     .ToListAsync();
                //
                // var productItemRepository = _unitOfWork.GetRepository<ProductItem>();
                //
                // // Add back the product quantities to the stock
                // foreach (var detail in orderDetails)
                // {
                //     var productItem = await productItemRepository.Entities
                //         .FirstOrDefaultAsync(p => p.Id == detail.ProductItemId && !p.DeletedTime.HasValue)
                //         ?? throw new BaseException.NotFoundException(StatusCodeHelper.NotFound.ToString(),
                //             string.Format(Constants.ErrorMessageProductItemNotFound, detail.ProductItemId));
                //
                //     productItem.QuantityInStock += detail.ProductQuantity;
                //
                //     productItemRepository.Update(productItem);
                //     await _unitOfWork.SaveAsync();
                // }

                //returnUrl = Constants.FrontUrl + "/Order/OrderHistory";
                response.IsSucceed = false;
                    response.Text = returnUrl;
                    return response;
                }


                response.IsSucceed = true;  
                response.Text = returnUrl;
                return response;

            }
            else
            {
                order.Status = "Awaiting Payment";
                order.PaymentMethodId = Guid.Parse("354EDA95-5BE5-41BE-ACC3-CFD70188118A");

                _unitOfWork.Orders.Update(order);
                await _unitOfWork.SaveChangesAsync();
                returnUrl = $"https://spss-fe-tuannguyen333s-projects.vercel.app/payment-failure?id={orderInfo}";

            // updateDto = new UpdateStatusOrderDto
            // {
            //     OrderId = order.Id,
            //     Status = "Payment Failed"
            // };
            //
            // await _orderService.UpdateOrderStatusAsync(order.UserId.ToString(), updateDto);

            // // Create a new status change record after updating the order status
            // var statusChangeDto = new StatusChangeForCreationDto
            // {
            //     OrderId = order.Id,
            //     Status = order.Status
            // };
            //
            // await _statusChangeService.Create(statusChangeDto, order.UserId.ToString());
            // await _unitOfWork.SaveAsync();

            // // Retrieve the order details to update product stock
            // var orderDetailRepository = _unitOfWork.GetRepository<OrderDetail>();
            // var orderDetails = await orderDetailRepository.Entities
            //     .Where(od => od.OrderId == order.Id)
            //     .ToListAsync();
            //
            // var productItemRepository = _unitOfWork.GetRepository<ProductItem>();
            //
            // // Add back the product quantities to the stock
            // foreach (var detail in orderDetails)
            // {
            //     var productItem = await productItemRepository.Entities
            //         .FirstOrDefaultAsync(p => p.Id == detail.ProductItemId && !p.DeletedTime.HasValue)
            //         ?? throw new BaseException.NotFoundException(StatusCodeHelper.NotFound.ToString(),
            //             string.Format(Constants.ErrorMessageProductItemNotFound, detail.ProductItemId));
            //
            //     productItem.QuantityInStock += detail.ProductQuantity;
            //
            //     productItemRepository.Update(productItem);
            //     await _unitOfWork.SaveAsync();
            // }


                response.IsSucceed = false;
                //returnUrl = Constants.FrontUrl + "/Order/OrderHistory";
                response.Text = returnUrl;
                return response;

            }
        }

        public string HashAllFields(Dictionary<string, string> fields)
            {
                // Sort the field names
                var sortedFieldNames = fields.Keys.OrderBy(k => k).ToList();
                var sb = new StringBuilder();

                foreach (var fieldName in sortedFieldNames)
                {
                    if (fields.TryGetValue(fieldName, out var fieldValue) && !(fieldValue == null))
                    {
                        if (sb.Length > 0)
                        {
                            sb.Append("&");
                        }
                        sb.Append(fieldName);
                        sb.Append("=");
                        sb.Append(Uri.EscapeDataString(fieldValue));
                    }
                }

                return HmacSHA512(vnp_HashSecret, sb.ToString());
            }





        public static string HmacSHA512(string key, string data)
        {
            if (key == null || data == null)
            {
                throw new ArgumentNullException();
            }

            try
            {
                using (var hmac = new HMACSHA512(Encoding.UTF8.GetBytes(key)))
                {
                    byte[] hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(data));
                    return BitConverter.ToString(hash).Replace("-", string.Empty).ToLower();
                }
            }
            catch (Exception)
            {
                return string.Empty;
            }
        }

        public string GetRandomNumber(int len)
        {
            Random rnd = new();
            const string chars = "0123456789";
            StringBuilder sb = new StringBuilder(len);
            for (int i = 0; i < len; i++)
            {
                sb.Append(chars[rnd.Next(chars.Length)]);
            }
            return sb.ToString();
        }
}