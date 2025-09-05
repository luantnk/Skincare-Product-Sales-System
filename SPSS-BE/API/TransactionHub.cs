using Microsoft.AspNetCore.SignalR;
using System;
using System.Collections.Concurrent;
using System.Linq;
using System.Threading.Tasks;
using BusinessObjects.Dto.Transaction;

namespace API
{
    public class TransactionHub : Hub
    {
        // L?u tr? �nh x? gi?a userId v� connectionId
        private static readonly ConcurrentDictionary<string, string> _userConnections = new ConcurrentDictionary<string, string>();
        
        // L?u tr? �nh x? gi?a transactionId v� userId
        private static readonly ConcurrentDictionary<string, string> _transactionUsers = new ConcurrentDictionary<string, string>();

        // L?u tr? danh s�ch adminId v� connectionId
        private static readonly ConcurrentDictionary<string, string> _adminConnections = new ConcurrentDictionary<string, string>();

        // Khi c� k?t n?i m?i
        public override async Task OnConnectedAsync()
        {
            string connectionId = Context.ConnectionId;
            Console.WriteLine($"New connection established: {connectionId}");
            await base.OnConnectedAsync();
        }

        // Khi ng?t k?t n?i
        public override async Task OnDisconnectedAsync(Exception exception)
        {
            string connectionId = Context.ConnectionId;
            Console.WriteLine($"Disconnected: {connectionId}");

            // X�a connection c?a admin n?u c�
            var adminIdToRemove = _adminConnections
                .FirstOrDefault(x => x.Value == connectionId).Key;

            if (adminIdToRemove != null)
            {
                Console.WriteLine($"Removing admin connection: {adminIdToRemove}");
                _adminConnections.TryRemove(adminIdToRemove, out _);
            }

            // X�a connection c?a user n?u c�
            var userIdToRemove = _userConnections
                .FirstOrDefault(x => x.Value == connectionId).Key;

            if (userIdToRemove != null)
            {
                Console.WriteLine($"Removing user connection: {userIdToRemove}");
                _userConnections.TryRemove(userIdToRemove, out _);
            }

            await base.OnDisconnectedAsync(exception);
        }

        // ??ng k� k?t n?i user
        public async Task RegisterUserConnection(string userId)
        {
            if (string.IsNullOrEmpty(userId))
            {
                await Clients.Caller.SendAsync("Error", "User ID is required");
                return;
            }

            // L?u �nh x? gi?a userId v� connectionId
            _userConnections.AddOrUpdate(userId, Context.ConnectionId, (key, oldValue) => Context.ConnectionId);
            
            Console.WriteLine($"User {userId} registered with connection {Context.ConnectionId}");
            await Clients.Caller.SendAsync("UserRegistered", userId);
        }

        // ??ng k� k?t n?i admin
        public async Task RegisterAdminConnection(string adminId)
        {
            if (string.IsNullOrEmpty(adminId))
            {
                await Clients.Caller.SendAsync("Error", "Admin ID is required");
                return;
            }

            // L?u �nh x? gi?a adminId v� connectionId
            _adminConnections.AddOrUpdate(adminId, Context.ConnectionId, (key, oldValue) => Context.ConnectionId);
            
            Console.WriteLine($"Admin {adminId} registered with connection {Context.ConnectionId}");
            await Clients.Caller.SendAsync("AdminRegistered", adminId);
        }

        // ??ng k� theo d�i transaction
        public async Task RegisterTransactionWatch(string transactionId, string userId)
        {
            if (string.IsNullOrEmpty(transactionId) || string.IsNullOrEmpty(userId))
            {
                await Clients.Caller.SendAsync("Error", "Transaction ID and User ID are required");
                return;
            }

            // L?u �nh x? gi?a transactionId v� userId
            _transactionUsers.AddOrUpdate(transactionId, userId, (key, oldValue) => userId);
            
            Console.WriteLine($"Transaction {transactionId} is being watched by user {userId}");
            await Clients.Caller.SendAsync("TransactionWatchRegistered", transactionId);
        }

        // Th�ng b�o c?p nh?t tr?ng th�i giao d?ch
        public async Task NotifyTransactionUpdated(string transactionId, TransactionDto transaction)
        {
            if (string.IsNullOrEmpty(transactionId) || transaction == null)
            {
                await Clients.Caller.SendAsync("Error", "Transaction ID and transaction data are required");
                return;
            }

            // T�m userId li�n quan ??n transaction
            if (_transactionUsers.TryGetValue(transactionId, out string userId))
            {
                // T�m connectionId c?a user
                if (_userConnections.TryGetValue(userId, out string userConnectionId))
                {
                    // G?i th�ng b�o cho user c? th?
                    await Clients.Client(userConnectionId).SendAsync("TransactionUpdated", transaction);
                    Console.WriteLine($"Notified user {userId} about transaction {transactionId} status update to {transaction.Status}");
                }
            }
        }

        // Th�ng b�o c� giao d?ch m?i c?n duy?t (g?i cho admin)
        public async Task NotifyNewTransaction(TransactionDto transaction)
        {
            if (transaction == null)
            {
                await Clients.Caller.SendAsync("Error", "Transaction data is required");
                return;
            }

            // G?i th�ng b�o cho t?t c? admin ?ang k?t n?i
            foreach (var adminConnection in _adminConnections)
            {
                await Clients.Client(adminConnection.Value).SendAsync("NewTransaction", transaction);
            }
            
            Console.WriteLine($"Notified all admins about new transaction {transaction.Id}");
        }
    }
}