// Admin Features Management
class AdminFeatures {
    constructor() {
        this.currentUsers = [];
        this.currentReports = [];
        this.currentSettings = {};
        this.init();
    }

    init() {
        this.bindEvents();
    }

    bindEvents() {
        // Users page events
        document.getElementById('user-search')?.addEventListener('input', (e) => {
            this.filterUsers(e.target.value);
        });

        document.querySelectorAll('#users-page .filter-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                this.filterUsersByStatus(btn.dataset.filter);
                document.querySelectorAll('#users-page .filter-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
            });
        });

        // Reports page events
        document.getElementById('report-search')?.addEventListener('input', (e) => {
            this.filterReports(e.target.value);
        });

        document.querySelectorAll('#reports-page .filter-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                this.filterReportsByType(btn.dataset.filter);
                document.querySelectorAll('#reports-page .filter-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
            });
        });

        // Settings page events
        document.getElementById('save-settings-btn')?.addEventListener('click', () => {
            this.saveSettings();
        });

        document.getElementById('reset-settings-btn')?.addEventListener('click', () => {
            this.resetSettings();
        });

        // Export buttons
        document.getElementById('export-users-btn')?.addEventListener('click', () => {
            this.exportUsers();
        });

        document.getElementById('export-reports-btn')?.addEventListener('click', () => {
            this.exportReports();
        });

        // Modal events
        this.bindModalEvents();
    }

    bindModalEvents() {
        // User modal events
        document.getElementById('ban-user-btn')?.addEventListener('click', () => {
            this.toggleUserBan();
        });

        document.getElementById('send-message-btn')?.addEventListener('click', () => {
            this.openSendMessageModal();
        });

        // Send message modal events
        document.getElementById('send-message-form')?.addEventListener('submit', (e) => {
            e.preventDefault();
            this.sendMessage();
        });

        document.getElementById('cancel-message-btn')?.addEventListener('click', () => {
            this.closeModal('send-message-modal');
        });

        document.getElementById('close-user-modal')?.addEventListener('click', () => {
            this.closeModal('user-modal');
        });

        // Report modal events
        document.getElementById('approve-report-btn')?.addEventListener('click', () => {
            this.approveReport();
        });

        document.getElementById('reject-report-btn')?.addEventListener('click', () => {
            this.rejectReport();
        });

        document.getElementById('contact-reporter-btn')?.addEventListener('click', () => {
            this.contactReporter();
        });

        document.getElementById('close-report-modal')?.addEventListener('click', () => {
            this.closeModal('report-modal');
        });

        // Close modals when clicking outside
        document.querySelectorAll('.modal').forEach(modal => {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) {
                    this.closeModal(modal.id);
                }
            });
        });

        document.querySelectorAll('.modal-close').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const modal = e.target.closest('.modal');
                if (modal) {
                    this.closeModal(modal.id);
                }
            });
        });
    }

    // Users Management
    async loadUsers() {
        try {
            this.showLoading('users-table-body');
            this.currentUsers = await FirebaseService.getUsers();
            this.displayUsers(this.currentUsers);
        } catch (error) {
            console.error('Error loading users:', error);
            this.showError('users-table-body', 'Failed to load users');
        }
    }

    displayUsers(users) {
        const tbody = document.getElementById('users-table-body');
        if (!tbody) return;

        if (users.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="8" class="text-center">
                        <div class="empty-state">
                            <i class="fas fa-users"></i>
                            <h3>No Users Found</h3>
                            <p>No users have registered yet.</p>
                        </div>
                    </td>
                </tr>
            `;
            return;
        }

        tbody.innerHTML = users.map(user => `
            <tr onclick="adminFeatures.showUserDetails('${user.id}')">
                <td>
                    <div class="user-info">
                        <div class="user-avatar">
                            <i class="fas fa-user"></i>
                        </div>
                        <div class="user-details">
                            <div class="user-name">${user.name || user.username || 'Unknown'}</div>
                            <div class="user-id">#${user.id.substring(0, 8)}</div>
                        </div>
                    </div>
                </td>
                <td>${user.email || 'Not provided'}</td>
                <td>${user.phone || user.phoneNumber || 'Not provided'}</td>
                <td>${this.formatDate(user.createdAt)}</td>
                <td>
                    <span class="status-badge ${user.status || 'active'}">
                        ${(user.status || 'active').toUpperCase()}
                    </span>
                </td>
                <td>${user.petsCount || 0}</td>
                <td>${user.reportsCount || 0}</td>
                <td>
                    <div class="action-buttons">
                        <button class="btn-small btn-info" onclick="event.stopPropagation(); adminFeatures.showUserDetails('${user.id}')">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn-small ${user.status === 'banned' ? 'btn-success' : 'btn-danger'}" 
                                onclick="event.stopPropagation(); adminFeatures.toggleUserBan('${user.id}')">
                            <i class="fas fa-${user.status === 'banned' ? 'user-check' : 'ban'}"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `).join('');
    }

    async showUserDetails(userId) {
        try {
            const user = await FirebaseService.getUserById(userId);
            if (!user) {
                alert('User not found');
                return;
            }

            const modal = document.getElementById('user-modal');
            const userDetails = document.getElementById('user-details');
            
            userDetails.innerHTML = `
                <div class="user-avatar-large">
                    <i class="fas fa-user"></i>
                </div>
                <div class="user-info-grid">
                    <div class="user-info-item">
                        <div class="user-info-label">Name</div>
                        <div class="user-info-value">${user.name || user.username || 'Unknown'}</div>
                    </div>
                    <div class="user-info-item">
                        <div class="user-info-label">Email</div>
                        <div class="user-info-value">${user.email || 'Not provided'}</div>
                    </div>
                    <div class="user-info-item">
                        <div class="user-info-label">Phone</div>
                        <div class="user-info-value">${user.phone || user.phoneNumber || 'Not provided'}</div>
                    </div>
                    <div class="user-info-item">
                        <div class="user-info-label">Status</div>
                        <div class="user-info-value">
                            <span class="status-badge ${user.status || 'active'}">
                                ${(user.status || 'active').toUpperCase()}
                            </span>
                        </div>
                    </div>
                    <div class="user-info-item">
                        <div class="user-info-label">Join Date</div>
                        <div class="user-info-value">${this.formatDate(user.createdAt)}</div>
                    </div>
                    <div class="user-info-item">
                        <div class="user-info-label">Last Active</div>
                        <div class="user-info-value">${user.lastActive ? this.formatDate(user.lastActive) : 'Never'}</div>
                    </div>
                </div>
            `;

            // Update ban button text
            const banBtn = document.getElementById('ban-user-btn');
            banBtn.innerHTML = user.status === 'banned' ? 
                '<i class="fas fa-user-check"></i> Unban User' : 
                '<i class="fas fa-ban"></i> Ban User';
            banBtn.dataset.userId = userId;
            banBtn.dataset.currentStatus = user.status || 'active';

            this.showModal('user-modal');
        } catch (error) {
            console.error('Error showing user details:', error);
            alert('Failed to load user details');
        }
    }

    async toggleUserBan(userId = null) {
        const banBtn = document.getElementById('ban-user-btn');
        const targetUserId = userId || banBtn.dataset.userId;
        const currentStatus = banBtn.dataset.currentStatus;

        try {
            if (currentStatus === 'banned') {
                await FirebaseService.unbanUser(targetUserId);
                alert('User unbanned successfully');
            } else {
                await FirebaseService.banUser(targetUserId);
                alert('User banned successfully');
            }
            
            this.closeModal('user-modal');
            this.loadUsers(); // Refresh the list
        } catch (error) {
            console.error('Error toggling user ban:', error);
            alert('Failed to update user status');
        }
    }

    filterUsers(searchTerm) {
        const filteredUsers = this.currentUsers.filter(user => {
            const name = (user.name || user.username || '').toLowerCase();
            const email = (user.email || '').toLowerCase();
            const search = searchTerm.toLowerCase();
            
            return name.includes(search) || email.includes(search);
        });
        
        this.displayUsers(filteredUsers);
    }

    filterUsersByStatus(status) {
        let filteredUsers = this.currentUsers;
        
        if (status !== 'all') {
            if (status === 'recent') {
                const lastWeek = new Date();
                lastWeek.setDate(lastWeek.getDate() - 7);
                filteredUsers = this.currentUsers.filter(user => 
                    user.createdAt >= lastWeek
                );
            } else {
                filteredUsers = this.currentUsers.filter(user => 
                    (user.status || 'active') === status
                );
            }
        }
        
        this.displayUsers(filteredUsers);
    }

    // Reports Management
    async loadReports() {
        try {
            this.showLoading('reports-grid');
            this.currentReports = await FirebaseService.getReports();
            this.displayReports(this.currentReports);
        } catch (error) {
            console.error('Error loading reports:', error);
            this.showError('reports-grid', 'Failed to load reports');
        }
    }

    displayReports(reports) {
        const grid = document.getElementById('reports-grid');
        if (!grid) return;

        if (reports.length === 0) {
            grid.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-file-alt"></i>
                    <h3>No Reports Found</h3>
                    <p>No pet reports have been submitted yet.</p>
                </div>
            `;
            return;
        }

        grid.innerHTML = reports.map(report => `
            <div class="report-card" onclick="adminFeatures.showReportDetails('${report.id}', '${report.collection}')">
                ${report.isUrgent ? '<div class="urgent-badge">URGENT</div>' : ''}
                <div class="report-header">
                    <span class="report-type ${report.type}">${report.type.toUpperCase()}</span>
                    <div class="report-title">${report.petDetails?.name || 'Unnamed Pet'}</div>
                    <div class="report-meta">
                        <i class="fas fa-calendar"></i>
                        ${this.formatDate(report.createdAt)}
                    </div>
                </div>
                <div class="report-content">
                    <div class="report-description">
                        ${this.truncateText(report.description || report.petDetails?.description || 'No description available', 100)}
                    </div>
                    <div class="report-tags">
                        <span class="report-tag">${report.petDetails?.type || 'Unknown'}</span>
                        <span class="report-tag">${report.petDetails?.breed || 'Mixed'}</span>
                        ${report.location ? `<span class="report-tag"><i class="fas fa-map-marker-alt"></i> ${report.location}</span>` : ''}
                    </div>
                </div>
                <div class="report-actions">
                    <button class="btn-small btn-success" onclick="event.stopPropagation(); adminFeatures.approveReport('${report.id}', '${report.collection}')">
                        <i class="fas fa-check"></i> Approve
                    </button>
                    <button class="btn-small btn-danger" onclick="event.stopPropagation(); adminFeatures.rejectReport('${report.id}', '${report.collection}')">
                        <i class="fas fa-times"></i> Reject
                    </button>
                    <button class="btn-small btn-info" onclick="event.stopPropagation(); adminFeatures.showReportDetails('${report.id}', '${report.collection}')">
                        <i class="fas fa-eye"></i> Details
                    </button>
                </div>
            </div>
        `).join('');
    }

    async showReportDetails(reportId, collection) {
        try {
            const report = await FirebaseService.getReportById(reportId, collection);
            if (!report) {
                alert('Report not found');
                return;
            }

            const modal = document.getElementById('report-modal');
            const reportDetails = document.getElementById('report-details');
            
            reportDetails.innerHTML = `
                <div class="report-details-content">
                    <div class="report-header">
                        <span class="report-type ${report.type}">${report.type.toUpperCase()}</span>
                        ${report.isUrgent ? '<span class="urgent-badge">URGENT</span>' : ''}
                        <h3>${report.petDetails?.name || 'Unnamed Pet'}</h3>
                    </div>
                    
                    <div class="report-info-grid">
                        <div class="report-info-section">
                            <h4>Pet Details</h4>
                            <p><strong>Type:</strong> ${report.petDetails?.type || 'Unknown'}</p>
                            <p><strong>Breed:</strong> ${report.petDetails?.breed || 'Mixed'}</p>
                            <p><strong>Age:</strong> ${report.petDetails?.age || 'Unknown'}</p>
                            <p><strong>Color:</strong> ${report.petDetails?.color || 'Unknown'}</p>
                            <p><strong>Gender:</strong> ${report.petDetails?.gender || 'Unknown'}</p>
                        </div>
                        
                        <div class="report-info-section">
                            <h4>Contact Information</h4>
                            <p><strong>Reporter:</strong> ${report.contactInfo?.name || 'Unknown'}</p>
                            <p><strong>Phone:</strong> ${report.contactInfo?.phone || 'Not provided'}</p>
                            <p><strong>Email:</strong> ${report.contactInfo?.email || 'Not provided'}</p>
                            <p><strong>Location:</strong> ${report.location || report.contactInfo?.address || 'Not provided'}</p>
                        </div>
                    </div>
                    
                    <div class="report-description">
                        <h4>Description</h4>
                        <p>${report.description || report.petDetails?.description || 'No description provided'}</p>
                    </div>
                    
                    <div class="report-meta">
                        <p><strong>Submitted:</strong> ${this.formatDate(report.createdAt)}</p>
                        <p><strong>Status:</strong> <span class="status-badge ${report.status || 'pending'}">${(report.status || 'pending').toUpperCase()}</span></p>
                    </div>
                </div>
            `;

            // Store current report data for actions
            modal.dataset.reportId = reportId;
            modal.dataset.collection = collection;

            this.showModal('report-modal');
        } catch (error) {
            console.error('Error showing report details:', error);
            alert('Failed to load report details');
        }
    }

    async approveReport(reportId = null, collection = null) {
        const modal = document.getElementById('report-modal');
        const targetReportId = reportId || modal.dataset.reportId;
        const targetCollection = collection || modal.dataset.collection;

        try {
            await FirebaseService.approveReport(targetReportId, targetCollection);
            alert('Report approved successfully');
            this.closeModal('report-modal');
            this.loadReports(); // Refresh the list
        } catch (error) {
            console.error('Error approving report:', error);
            alert('Failed to approve report');
        }
    }

    async rejectReport(reportId = null, collection = null) {
        const modal = document.getElementById('report-modal');
        const targetReportId = reportId || modal.dataset.reportId;
        const targetCollection = collection || modal.dataset.collection;

        if (!confirm('Are you sure you want to reject this report?')) {
            return;
        }

        try {
            await FirebaseService.rejectReport(targetReportId, targetCollection);
            alert('Report rejected successfully');
            this.closeModal('report-modal');
            this.loadReports(); // Refresh the list
        } catch (error) {
            console.error('Error rejecting report:', error);
            alert('Failed to reject report');
        }
    }

    filterReports(searchTerm) {
        const filteredReports = this.currentReports.filter(report => {
            const petName = (report.petDetails?.name || '').toLowerCase();
            const description = (report.description || '').toLowerCase();
            const location = (report.location || '').toLowerCase();
            const search = searchTerm.toLowerCase();
            
            return petName.includes(search) || description.includes(search) || location.includes(search);
        });
        
        this.displayReports(filteredReports);
    }

    filterReportsByType(type) {
        let filteredReports = this.currentReports;
        
        if (type !== 'all') {
            if (type === 'urgent') {
                filteredReports = this.currentReports.filter(report => report.isUrgent);
            } else {
                filteredReports = this.currentReports.filter(report => report.type === type);
            }
        }
        
        this.displayReports(filteredReports);
    }

    // Settings Management
    async loadSettings() {
        try {
            this.currentSettings = await FirebaseService.getSettings();
            this.populateSettingsForm();
        } catch (error) {
            console.error('Error loading settings:', error);
            alert('Failed to load settings');
        }
    }

    populateSettingsForm() {
        const settings = this.currentSettings;
        
        document.getElementById('app-name').value = settings.appName || '';
        document.getElementById('app-description').value = settings.appDescription || '';
        document.getElementById('maintenance-mode').value = settings.maintenanceMode || 'false';
        document.getElementById('email-notifications').value = settings.emailNotifications || 'true';
        document.getElementById('push-notifications').value = settings.pushNotifications || 'true';
        document.getElementById('admin-email').value = settings.adminEmail || '';
        document.getElementById('auto-approve-reports').value = settings.autoApproveReports || 'false';
        document.getElementById('max-images-per-report').value = settings.maxImagesPerReport || 5;
        document.getElementById('report-expiry-days').value = settings.reportExpiryDays || 30;
    }

    async saveSettings() {
        try {
            const settings = {
                appName: document.getElementById('app-name').value,
                appDescription: document.getElementById('app-description').value,
                maintenanceMode: document.getElementById('maintenance-mode').value === 'true',
                emailNotifications: document.getElementById('email-notifications').value === 'true',
                pushNotifications: document.getElementById('push-notifications').value === 'true',
                adminEmail: document.getElementById('admin-email').value,
                autoApproveReports: document.getElementById('auto-approve-reports').value === 'true',
                maxImagesPerReport: parseInt(document.getElementById('max-images-per-report').value),
                reportExpiryDays: parseInt(document.getElementById('report-expiry-days').value)
            };

            await FirebaseService.saveSettings(settings);
            alert('Settings saved successfully');
            this.currentSettings = settings;
        } catch (error) {
            console.error('Error saving settings:', error);
            alert('Failed to save settings');
        }
    }

    async resetSettings() {
        if (!confirm('Are you sure you want to reset all settings to default values?')) {
            return;
        }

        try {
            const defaultSettings = FirebaseService.getDefaultSettings();
            await FirebaseService.saveSettings(defaultSettings);
            this.currentSettings = defaultSettings;
            this.populateSettingsForm();
            alert('Settings reset to default values');
        } catch (error) {
            console.error('Error resetting settings:', error);
            alert('Failed to reset settings');
        }
    }

    // Export Functions
    exportUsers() {
        if (this.currentUsers.length === 0) {
            alert('No users to export');
            return;
        }

        const csv = this.convertToCSV(this.currentUsers, [
            { key: 'id', label: 'ID' },
            { key: 'name', label: 'Name' },
            { key: 'email', label: 'Email' },
            { key: 'phone', label: 'Phone' },
            { key: 'status', label: 'Status' },
            { key: 'createdAt', label: 'Join Date', format: 'date' }
        ]);

        this.downloadCSV(csv, 'users-export.csv');
    }

    exportReports() {
        if (this.currentReports.length === 0) {
            alert('No reports to export');
            return;
        }

        const csv = this.convertToCSV(this.currentReports, [
            { key: 'id', label: 'ID' },
            { key: 'type', label: 'Type' },
            { key: 'petDetails.name', label: 'Pet Name' },
            { key: 'petDetails.type', label: 'Pet Type' },
            { key: 'location', label: 'Location' },
            { key: 'status', label: 'Status' },
            { key: 'createdAt', label: 'Created Date', format: 'date' }
        ]);

        this.downloadCSV(csv, 'reports-export.csv');
    }

    // Utility Functions
    formatDate(date) {
        if (!date) return 'Unknown';
        return new Date(date).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    truncateText(text, maxLength) {
        if (text.length <= maxLength) return text;
        return text.substring(0, maxLength) + '...';
    }

    showModal(modalId) {
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.classList.add('show');
            document.body.style.overflow = 'hidden';
        }
    }

    closeModal(modalId) {
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.classList.remove('show');
            document.body.style.overflow = 'auto';
        }
    }

    showLoading(elementId) {
        const element = document.getElementById(elementId);
        if (element) {
            element.innerHTML = `
                <div class="loading-state">
                    <i class="fas fa-spinner fa-spin"></i>
                    <p>Loading...</p>
                </div>
            `;
        }
    }

    showError(elementId, message) {
        const element = document.getElementById(elementId);
        if (element) {
            element.innerHTML = `
                <div class="error-state">
                    <i class="fas fa-exclamation-triangle"></i>
                    <p>${message}</p>
                </div>
            `;
        }
    }

    convertToCSV(data, columns) {
        const headers = columns.map(col => col.label).join(',');
        const rows = data.map(item => {
            return columns.map(col => {
                let value = this.getNestedValue(item, col.key);
                
                if (col.format === 'date' && value) {
                    value = this.formatDate(value);
                }
                
                // Escape commas and quotes
                if (typeof value === 'string') {
                    value = '"' + value.replace(/"/g, '""') + '"';
                }
                
                return value || '';
            }).join(',');
        });
        
        return [headers, ...rows].join('\n');
    }

    getNestedValue(obj, path) {
        return path.split('.').reduce((current, prop) => current && current[prop], obj);
    }

    downloadCSV(csv, filename) {
        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        
        if (link.download !== undefined) {
            const url = URL.createObjectURL(blob);
            link.setAttribute('href', url);
            link.setAttribute('download', filename);
            link.style.visibility = 'hidden';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
    }

    // Messaging Functions
    openSendMessageModal() {
        const banBtn = document.getElementById('ban-user-btn');
        const userId = banBtn.dataset.userId;
        const userName = this.currentUsers.find(user => user.id === userId)?.name || 'Unknown User';
        
        // Set recipient info
        document.getElementById('message-recipient').value = `${userName} (${userId.substring(0, 8)})`;
        
        // Store userId for sending
        const messageModal = document.getElementById('send-message-modal');
        messageModal.dataset.userId = userId;
        
        // Clear form
        document.getElementById('send-message-form').reset();
        
        // Show modal
        this.showModal('send-message-modal');
    }

    async sendMessage() {
        try {
            const messageModal = document.getElementById('send-message-modal');
            const userId = messageModal.dataset.userId;
            
            const messageData = {
                subject: document.getElementById('message-subject').value,
                content: document.getElementById('message-content').value,
                type: document.getElementById('message-type').value
            };

            // Validate
            if (!messageData.subject.trim() || !messageData.content.trim()) {
                alert('Please fill in all required fields');
                return;
            }

            // Show loading
            const submitBtn = document.querySelector('#send-message-form button[type="submit"]');
            const originalText = submitBtn.innerHTML;
            submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Sending...';
            submitBtn.disabled = true;

            // Send message
            await FirebaseService.sendMessageToUser(userId, messageData);
            
            // Success
            alert('Message sent successfully!');
            this.closeModal('send-message-modal');
            
        } catch (error) {
            console.error('Error sending message:', error);
            alert('Failed to send message. Please try again.');
        } finally {
            // Reset button
            const submitBtn = document.querySelector('#send-message-form button[type="submit"]');
            if (submitBtn) {
                submitBtn.innerHTML = '<i class="fas fa-paper-plane"></i> Send Message';
                submitBtn.disabled = false;
            }
        }
    }

    sendMessageToUser() {
        this.openSendMessageModal();
    }

    contactReporter() {
        // This would typically open phone dialer or email client
        alert('Contact functionality would be implemented here');
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.adminFeatures = new AdminFeatures();
}); 