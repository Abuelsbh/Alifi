// Admin Features Management
class AdminFeatures {
    constructor() {
        this.currentUsers = [];
        this.currentReports = [];
        this.currentSettings = {};
        this.currentAds = [];
        this.currentAdmins = []; // Added for admins data
        this.currentViewingUser = null; // Added for tracking the currently viewed user
        this.currentViewingReport = null; // Added for tracking the currently viewed report
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

        // Admins page events (Added)
        document.getElementById('admin-search')?.addEventListener('input', (e) => {
            this.filterAdmins(e.target.value);
        });

        // Modal events
        this.bindModalEvents();

        // Ensure the global adminFeatures object is available for inline event handlers
        window.adminFeatures = this;
    }

    bindModalEvents() {
        // User modal events
        document.getElementById('ban-user-btn')?.addEventListener('click', () => {
            this.toggleUserBan(this.currentViewingUser?.id);
        });

        document.getElementById('send-message-btn')?.addEventListener('click', () => {
            this.openSendMessageModal(this.currentViewingUser?.id);
        });

        // Send message modal events
        document.getElementById('send-message-form')?.addEventListener('submit', (e) => {
            e.preventDefault();
            this.sendMessage();
        });

        document.getElementById('cancel-message-btn')?.addEventListener('click', () => {
            this.closeModal('send-message-modal');
        });

        // Send message to all users button
        document.getElementById('send-message-all-btn')?.addEventListener('click', () => {
            this.openSendMessageToAllModal();
        });

        // Send message to all users modal events
        document.getElementById('send-message-all-form')?.addEventListener('submit', (e) => {
            e.preventDefault();
            this.sendMessageToAllUsers();
        });

        document.getElementById('cancel-message-all-btn')?.addEventListener('click', () => {
            this.closeModal('send-message-all-modal');
        });

        document.getElementById('close-user-modal')?.addEventListener('click', () => {
            this.closeModal('user-modal');
        });

        // Report modal events
        document.getElementById('approve-report-btn')?.addEventListener('click', () => {
            this.approveReport(this.currentViewingReport?.id, this.currentViewingReport?.collection);
        });

        document.getElementById('reject-report-btn')?.addEventListener('click', () => {
            this.rejectReport(this.currentViewingReport?.id, this.currentViewingReport?.collection);
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

    // Admins Management (New Section)
    async loadAdmins() {
        try {
            this.showLoading('admins-table-body');
            const admins = await FirebaseService.getAdmins();
            this.currentAdmins = admins;
            this.displayAdmins(this.currentAdmins);
        } catch (error) {
            console.error('Error loading admins:', error);
            this.showError('admins-table-body', 'Failed to load administrators');
        }
    }

    displayAdmins(admins) {
        const tbody = document.getElementById('admins-table-body');
        if (!tbody) return;

        if (admins.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="6" class="text-center">
                        <div class="empty-state">
                            <i class="fas fa-user-shield"></i>
                            <h3>No Admins Found</h3>
                            <p>Add your first administrator to manage the dashboard.</p>
                            <button class="btn btn-primary" onclick="window.adminFeatures.openAddAdminModal()">
                                <i class="fas fa-plus"></i>
                                Add New Admin
                            </button>
                        </div>
                    </td>
                </tr>
            `;
            return;
        }

        tbody.innerHTML = admins.map(admin => `
            <tr>
                <td>
                    <div class="user-info">
                        <div class="user-avatar">
                            <i class="fas fa-user-shield"></i>
                        </div>
                        <div class="user-details">
                            <div class="user-name">${admin.name || 'Unknown Admin'}</div>
                            <div class="user-id">#${admin.id.substring(0, 8)}</div>
                        </div>
                    </div>
                </td>
                <td>${admin.email || 'N/A'}</td>
                <td>
                    <span class="role-badge role-${admin.role}">
                        ${admin.roleName}
                    </span>
                </td>
                <td>${admin.uid}</td>
                <td>${admin.lastSignInTime ? this.formatDate(admin.lastSignInTime) : 'Never'}</td>
                <td>
                    <button class="btn-small btn-danger" onclick="window.adminFeatures.confirmDeleteAdmin('${admin.uid}', '${admin.name || admin.email}')">
                        <i class="fas fa-trash"></i> Delete
                    </button>
                </td>
            </tr>
        `).join('');
    }

    filterAdmins(searchTerm) {
        const filteredAdmins = this.currentAdmins.filter(admin => {
            const name = (admin.name || admin.email || '').toLowerCase();
            const email = (admin.email || '').toLowerCase();
            const uid = (admin.uid || '').toLowerCase();
            const search = searchTerm.toLowerCase();
            
            return name.includes(search) || email.includes(search) || uid.includes(search);
        });
        this.displayAdmins(filteredAdmins);
    }

    openAddAdminModal() {
        document.getElementById('admin-modal-title').textContent = 'Add New Admin';
        document.getElementById('add-admin-form').reset();
        this.showModal('add-admin-modal');
    }

    async handleAddAdminSubmit() {
        const name = document.getElementById('admin-name').value.trim();
        const email = document.getElementById('admin-email').value.trim();
        const password = document.getElementById('admin-password').value;
        const role = document.getElementById('admin-role').value;

        if (!name || !email || !password || !role) {
            alert('Please fill in all fields.');
            return;
        }

        const saveBtn = document.getElementById('save-admin-btn');
        saveBtn.classList.add('loading');
        saveBtn.disabled = true;

        try {
            const result = await FirebaseService.createAdminWithRole(email, password, name, role);
            if (result.success) {
                alert(`Admin added successfully with role: ${result.message}`);
                this.closeModal('add-admin-modal');
                this.loadAdmins(); // Refresh the list
            } else {
                // Check if it's an email exists error
                if (result.code === 'email-exists') {
                    const userChoice = confirm(`${result.error}\n\nWould you like to add admin privileges to the existing user instead?`);
                    if (userChoice) {
                        // Try to add admin privileges to existing user
                        const privilegeResult = await FirebaseService.addAdminPrivileges(email, name, role);
                        if (privilegeResult.success) {
                            alert(`Admin privileges added successfully with role: ${privilegeResult.message}`);
                            this.closeModal('add-admin-modal');
                            this.loadAdmins(); // Refresh the list
                        } else {
                            alert(privilegeResult.error || 'Failed to add admin privileges.');
                        }
                    }
                } else {
                    alert(result.error || 'Failed to add admin.');
                }
            }
        } catch (error) {
            console.error('Error adding admin:', error);
            alert('Failed to add admin: ' + error.message);
        } finally {
            saveBtn.classList.remove('loading');
            saveBtn.disabled = false;
        }
    }

    confirmDeleteAdmin(uid, name) {
        if (confirm(`Are you sure you want to delete admin \"${name}\"? This action cannot be undone and will remove their admin privileges.`)) {
            this.deleteAdmin(uid);
        }
    }

    async deleteAdmin(uid) {
        try {
            // Remove admin claim and delete user from authentication
            const result = await FirebaseService.removeAdmin(uid);
            if (result.success) {
                alert('Admin deleted successfully!');
                this.loadAdmins(); // Refresh the list
            } else {
                alert(result.error || 'Failed to delete admin.');
            }
        } catch (error) {
            console.error('Error deleting admin:', error);
            alert('Failed to delete admin: ' + error.message);
        }
    }

    // Users Management
    async loadUsers() {
        try {
            this.showLoading('users-table-body');
            const users = await FirebaseService.getUsers(); // Directly get the array of users
            this.currentUsers = users;
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
            <tr onclick="window.adminFeatures.showUserDetails('${user.id}')">
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
                        <button class="btn-small btn-info" onclick="event.stopPropagation(); window.adminFeatures.showUserDetails('${user.id}')">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn-small ${user.status === 'banned' ? 'btn-success' : 'btn-danger'}" 
                                onclick="event.stopPropagation(); window.adminFeatures.toggleUserBan('${user.id}')">
                            <i class="fas fa-${user.status === 'banned' ? 'user-check' : 'ban'}"></i>
                        </button>
                        <button class="btn-small btn-danger" 
                                onclick="event.stopPropagation(); window.adminFeatures.deleteUser('${user.id}', '${(user.name || user.username || 'User').replace(/'/g, "\\'")}')"
                                title="Delete User Permanently">
                            <i class="fas fa-trash"></i>
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

            this.currentViewingUser = user; // Store the user being viewed

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
            if (banBtn) {
                banBtn.innerHTML = user.status === 'banned' ? 
                    '<i class="fas fa-user-check"></i> Unban User' : 
                    '<i class="fas fa-ban"></i> Ban User';
                banBtn.dataset.userId = userId;
                banBtn.dataset.currentStatus = user.status || 'active';
            }

            this.showModal('user-modal');
        } catch (error) {
            console.error('Error showing user details:', error);
            alert('Failed to load user details');
        }
    }

    async toggleUserBan(userId) {
        const targetUserId = userId || this.currentViewingUser?.id; // Use currentViewingUser if userId is not passed
        if (!targetUserId) {
            console.error('No user ID provided for toggling ban status.');
            return;
        }
        const user = this.currentUsers.find(u => u.id === targetUserId);
        const currentStatus = user?.status || 'active';

        try {
            if (currentStatus === 'banned') {
                // This function should return a success/error object if FirebaseService.unbanUser does
                await FirebaseService.unbanUser(targetUserId);
                alert('User unbanned successfully');
            } else {
                // This function should return a success/error object if FirebaseService.banUser does
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

    async deleteUser(userId, userName) {
        if (!userId) {
            console.error('No user ID provided for deletion.');
            return;
        }

        const confirmed = confirm(`هل أنت متأكد من حذف المستخدم "${userName}" نهائياً؟\n\nهذا الإجراء لا يمكن التراجع عنه.\n\nAre you sure you want to permanently delete user "${userName}"?\n\nThis action cannot be undone.`);
        
        if (!confirmed) {
            return;
        }

        try {
            const result = await FirebaseService.deleteUser(userId);
            if (result.success) {
                alert('تم حذف المستخدم بنجاح\nUser deleted successfully');
                this.closeModal('user-modal');
                this.loadUsers(); // Refresh the list
            } else {
                alert('فشل حذف المستخدم: ' + (result.error || 'Unknown error') + '\nFailed to delete user: ' + (result.error || 'Unknown error'));
            }
        } catch (error) {
            console.error('Error deleting user:', error);
            alert('فشل حذف المستخدم: ' + error.message + '\nFailed to delete user: ' + error.message);
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
                filteredUsers = this.currentUsers.filter(user => {
                    // Ensure createdAt is a Date object or convert it
                    const createdAtDate = user.createdAt instanceof Date ? user.createdAt : new Date(user.createdAt);
                    return createdAtDate >= lastWeek;
                });
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
            const reports = await FirebaseService.getReports(); // Directly get the array of reports
            this.currentReports = reports;
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

        grid.innerHTML = reports.map(report => {
            // Ensure we use the correct document ID
            const reportId = report.id || report.docId;
            const collection = report.collection;
            console.log('Displaying report:', { reportId, collection, fullReport: report });
            
            return `
            <div class="report-card" onclick="window.adminFeatures.showReportDetails('${reportId}', '${collection}')">
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
                    <button class="btn-small btn-success" onclick="event.stopPropagation(); window.adminFeatures.approveReport('${reportId}', '${collection}')">
                        <i class="fas fa-check"></i> Approve
                    </button>
                    <button class="btn-small btn-danger" onclick="event.stopPropagation(); window.adminFeatures.rejectReport('${reportId}', '${collection}')">
                        <i class="fas fa-times"></i> Reject
                    </button>
                    <button class="btn-small btn-info" onclick="event.stopPropagation(); window.adminFeatures.showReportDetails('${reportId}', '${collection}')">
                        <i class="fas fa-eye"></i> Details
                    </button>
                </div>
            </div>
        `;
        }).join('');
    }

    async showReportDetails(reportId, collection) {
        try {
            console.log('Fetching report details:', { reportId, collection });
            if (!reportId || !collection) {
                alert('Missing report ID or collection');
                return;
            }
            
            const report = await FirebaseService.getReportById(reportId, collection);
            if (!report) {
                console.error('Report not found:', { reportId, collection });
                alert('Report not found. Please check the console for details.');
                return;
            }
            
            console.log('Report loaded successfully:', report);

            // Store the report being viewed with explicit id and collection
            this.currentViewingReport = {
                id: reportId,
                collection: collection,
                ...report
            };
            console.log('Stored currentViewingReport:', this.currentViewingReport);

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
                        <p><strong>Approval Status:</strong> <span class="status-badge ${report.approvalStatus || 'pending'}">${(report.approvalStatus || 'pending').toUpperCase()}</span></p>
                        ${report.status ? `<p><strong>Report Status:</strong> <span class="status-badge ${report.status}">${report.status.toUpperCase()}</span></p>` : ''}
                    </div>
                </div>
            `;
            
            if (modal) {
                modal.dataset.reportId = reportId;
                modal.dataset.collection = collection;
            }

            this.showModal('report-modal');
        } catch (error) {
            console.error('Error showing report details:', error);
            alert('Failed to load report details');
        }
    }

    async approveReport(reportId = null, collection = null) {
        const targetReportId = reportId || this.currentViewingReport?.id;
        const targetCollection = collection || this.currentViewingReport?.collection;

        console.log('approveReport called with:', { reportId, collection, targetReportId, targetCollection });

        if (!targetReportId || !targetCollection) {
            console.error('No report ID or collection provided for approving report.');
            alert('Error: Missing report ID or collection');
            return;
        }

        try {
            console.log('Calling FirebaseService.approveReport...');
            const result = await FirebaseService.approveReport(targetReportId, targetCollection);
            console.log('Approve result:', result);
            
            if (result.success) {
                alert('Report approved successfully');
                this.closeModal('report-modal');
                this.loadReports(); // Refresh the list
            } else {
                alert('Failed to approve report: ' + (result.error || 'Unknown error'));
            }
        } catch (error) {
            console.error('Error approving report:', error);
            alert('Failed to approve report: ' + error.message);
        }
    }

    async rejectReport(reportId = null, collection = null) {
        const targetReportId = reportId || this.currentViewingReport?.id;
        const targetCollection = collection || this.currentViewingReport?.collection;

        if (!targetReportId || !targetCollection) {
            console.error('No report ID or collection provided for rejecting report.');
            return;
        }

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

    async deleteAllReports() {
        const confirmed = confirm('هل أنت متأكد من حذف جميع التقارير؟\n\nهذا الإجراء لا يمكن التراجع عنه وسيتم حذف جميع التقارير النشطة.\n\nAre you sure you want to delete all reports?\n\nThis action cannot be undone and will delete all active reports.');
        
        if (!confirmed) {
            return;
        }

        try {
            // Show loading
            const grid = document.getElementById('reports-grid');
            if (grid) {
                grid.innerHTML = '<div class="empty-state"><i class="fas fa-spinner fa-spin"></i><h3>Deleting reports...</h3></div>';
            }

            const result = await FirebaseService.deleteAllReports();
            
            if (result.success) {
                alert(`تم حذف ${result.deletedCount || 0} تقرير بنجاح\nSuccessfully deleted ${result.deletedCount || 0} reports`);
                this.loadReports(); // Refresh the list
            } else {
                alert('فشل حذف التقارير: ' + (result.error || 'Unknown error') + '\nFailed to delete reports: ' + (result.error || 'Unknown error'));
                this.loadReports(); // Refresh anyway to show current state
            }
        } catch (error) {
            console.error('Error deleting all reports:', error);
            alert('فشل حذف التقارير: ' + error.message + '\nFailed to delete reports: ' + error.message);
            this.loadReports(); // Refresh anyway to show current state
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
            const result = await FirebaseService.getSettings(); // Fetch settings
            if (result.success) {
                this.currentSettings = result.data;
                this.populateSettingsForm();
            } else {
                console.error('Error fetching settings:', result.error);
                alert('Failed to load settings');
            }
        } catch (error) {
            console.error('Error loading settings:', error);
            alert('Failed to load settings');
        }
    }

    populateSettingsForm() {
        const settings = this.currentSettings;
        
        // Use optional chaining and nullish coalescing for safer access
        document.getElementById('app-name').value = settings.appName ?? '';
        document.getElementById('app-description').value = settings.appDescription ?? '';
        document.getElementById('maintenance-mode').value = settings.maintenanceMode?.toString() ?? 'false';
        document.getElementById('email-notifications').value = settings.emailNotifications?.toString() ?? 'true';
        document.getElementById('push-notifications').value = settings.pushNotifications?.toString() ?? 'true';
        document.getElementById('admin-email').value = settings.adminEmail ?? '';
        document.getElementById('auto-approve-reports').value = settings.autoApproveReports?.toString() ?? 'false';
        document.getElementById('max-images-per-report').value = settings.maxImagesPerReport ?? 5;
        document.getElementById('report-expiry-days').value = settings.reportExpiryDays ?? 30;
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

            const result = await FirebaseService.saveSettings(settings);
            if (result.success) {
                alert('Settings saved successfully');
                this.currentSettings = settings;
            } else {
                console.error('Error saving settings:', result.error);
                alert('Failed to save settings');
            }
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
            const defaultSettings = FirebaseService.getDefaultSettings(); // Assuming this returns default settings
            const result = await FirebaseService.saveSettings(defaultSettings);
            if (result.success) {
                this.currentSettings = defaultSettings;
                this.populateSettingsForm();
                alert('Settings reset to default values');
            } else {
                console.error('Error saving default settings:', result.error);
                alert('Failed to reset settings');
            }
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
        // Ensure date is a valid Date object before formatting
        const d = new Date(date);
        if (isNaN(d.getTime())) return 'Invalid Date';
        return d.toLocaleDateString('en-US', {
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
        console.log('showModal called with ID:', modalId);
        const modal = document.getElementById(modalId);
        console.log('Modal element found:', modal);
        if (modal) {
            console.log('Adding show class to modal...');
            modal.classList.add('show');
            document.body.style.overflow = 'hidden';
            console.log('Modal classes after adding show:', modal.classList.toString());
        } else {
            console.error('Modal not found with ID:', modalId);
        }
    }

    closeModal(modalId) {
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.classList.remove('show');
            document.body.style.overflow = 'auto';
            // Clear current viewing user/report when modal closes
            if (modalId === 'user-modal') this.currentViewingUser = null;
            if (modalId === 'report-modal') this.currentViewingReport = null;
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


    // Advertisements Management
    async loadAds() {
        try {
            this.showLoading('ads-grid');
            const result = await FirebaseService.getAllAds();
            
            if (result.success) {
                this.currentAds = result.data;
                this.displayAds(result.data);
            } else {
                this.showError('ads-grid', result.error || 'Failed to load advertisements');
            }
        } catch (error) {
            console.error('Error loading ads:', error);
            this.showError('ads-grid', 'Failed to load advertisements');
        }
    }

    displayAds(ads) {
        const grid = document.getElementById('ads-grid');
        if (!grid) return;

        if (ads.length === 0) {
            grid.innerHTML = `
                <div class="ads-empty-state">
                    <i class="fas fa-ad"></i>
                    <h3>No Advertisements</h3>
                    <p>No advertisements have been created yet. Click "Add Advertisement" to create your first ad.</p>
                    <button class="btn btn-primary" onclick="window.adminFeatures.showAddAdModal()">
                        <i class="fas fa-plus"></i>
                        Add First Advertisement
                    </button>
                </div>
            `;
            return;
        }

        grid.innerHTML = ads.map(ad => `
            <div class="ad-card ${ad.isActive ? 'active' : 'inactive'}">
                <div class="ad-image">
                    ${ad.imageUrl ? 
                        `<img src="${ad.imageUrl}" alt="${ad.title || 'Advertisement'}" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                         <div style="display:none; width:100%; height:100%; align-items:center; justify-content:center; background:#f8f9fa; color:#6c757d;">
                            <i class="fas fa-image"></i> Image not available
                         </div>` : 
                        `<i class="fas fa-image"></i> No image`
                    }
                </div>
                <div class="ad-content">
                    <div class="ad-header">
                        <div>
                            ${ad.title ? `<h4 class="ad-title">${ad.title}</h4>` : ''}
                            ${ad.description ? `<p class="ad-description">${ad.description}</p>` : ''}
                        </div>
                    </div>
                    <div class="ad-meta">
                        <span class="ad-order">Order: ${ad.displayOrder}</span>
                        <div class="ad-stats">
                            <span><i class="fas fa-eye"></i> ${ad.views || 0}</span>
                            <span><i class="fas fa-mouse-pointer"></i> ${ad.clickCount || 0}</span>
                        </div>
                    </div>
                    <div class="ad-actions">
                        <button class="btn-small btn-preview" onclick="window.adminFeatures.previewAd('${ad.id}')">
                            <i class="fas fa-eye"></i> Preview
                        </button>
                        <button class="btn-small btn-edit" onclick="window.adminFeatures.editAd('${ad.id}')">
                            <i class="fas fa-edit"></i> Edit
                        </button>
                        <button class="btn-small btn-toggle ${ad.isActive ? 'active' : ''}" onclick="window.adminFeatures.toggleAdStatus('${ad.id}', ${!ad.isActive})">
                            <i class="fas fa-${ad.isActive ? 'eye-slash' : 'eye'}"></i> ${ad.isActive ? 'Deactivate' : 'Activate'}
                        </button>
                        <button class="btn-small btn-delete" onclick="window.adminFeatures.deleteAd('${ad.id}')">
                            <i class="fas fa-trash"></i> Delete
                        </button>
                    </div>
                </div>
            </div>
        `).join('');
    }

    async showAddAdModal() {
        console.log('showAddAdModal called!');
        const modal = document.getElementById('ad-modal');
        console.log('Modal element:', modal);
        
        document.getElementById('ad-modal-title').textContent = 'Add Advertisement';
        document.getElementById('ad-form').reset();
        document.getElementById('ad-form').dataset.mode = 'add';
        delete document.getElementById('ad-form').dataset.adId;
        
        // Reset image preview
        const imagePreview = document.getElementById('ad-image-preview');
        if (imagePreview) {
            imagePreview.style.display = 'none';
        }
        const imageInput = document.getElementById('ad-image-url');
        if (imageInput) {
            imageInput.required = true; // Required when adding
        }
        
        // Load locations and set default to "all"
        await this.loadAdLocations();
        document.getElementById('ad-location-all').checked = true;
        this.toggleLocationCheckboxes(false);
        
        console.log('About to show modal...');
        this.showModal('ad-modal');
        console.log('Modal should be shown now');
    }
    
    async loadAdLocations() {
        try {
            const result = await FirebaseService.getAllLocations();
            if (result.success && result.data) {
                const locationsList = document.getElementById('ad-locations-list');
                if (!locationsList) return;
                
                locationsList.innerHTML = result.data
                    .filter(loc => loc.isActive !== false)
                    .map(loc => `
                        <div style="margin-bottom: 8px;">
                            <label class="checkbox-label">
                                <input type="checkbox" class="ad-location-checkbox" value="${loc.id}" data-location-name="${loc.name}">
                                <span class="checkmark"></span>
                                ${loc.name}
                            </label>
                        </div>
                    `).join('');
            }
        } catch (error) {
            console.error('Error loading locations:', error);
            document.getElementById('ad-locations-list').innerHTML = '<p style="color: #f44336;">Failed to load locations</p>';
        }
    }
    
    toggleLocationCheckboxes(disabled) {
        const checkboxes = document.querySelectorAll('.ad-location-checkbox');
        checkboxes.forEach(cb => cb.disabled = disabled);
    }

    async editAd(adId) {
        try {
            const ad = this.currentAds.find(a => a.id === adId);
            if (!ad) {
                alert('Advertisement not found');
                return;
            }

            const imageInput = document.getElementById('ad-image-url');
            const imagePreview = document.getElementById('ad-image-preview');
            const imagePreviewImg = document.getElementById('ad-image-preview-img');

            document.getElementById('ad-modal-title').textContent = 'Edit Advertisement';
            document.getElementById('ad-title').value = ad.title || '';
            document.getElementById('ad-description').value = ad.description || '';
            document.getElementById('ad-display-order').value = ad.displayOrder || 1;
            document.getElementById('ad-click-url').value = ad.clickUrl || '';
            document.getElementById('ad-is-active').checked = ad.isActive !== false;
            
            // Show existing image preview
            if (ad.imageUrl) {
                imagePreviewImg.src = ad.imageUrl;
                imagePreview.style.display = 'block';
            } else {
                imagePreview.style.display = 'none';
            }
            
            // Clear file input (user can select new image if needed)
            imageInput.value = '';
            imageInput.required = false; // Not required when editing
            
            // Load locations and set selected ones
            await this.loadAdLocations();
            
            // Set location checkboxes
            const locations = ad.locations || [];
            if (locations.includes('all') || !locations || locations.length === 0) {
                document.getElementById('ad-location-all').checked = true;
                this.toggleLocationCheckboxes(false);
            } else {
                document.getElementById('ad-location-all').checked = false;
                this.toggleLocationCheckboxes(false);
                locations.forEach(locId => {
                    const checkbox = document.querySelector(`.ad-location-checkbox[value="${locId}"]`);
                    if (checkbox) checkbox.checked = true;
                });
            }
            
            document.getElementById('ad-form').dataset.mode = 'edit';
            document.getElementById('ad-form').dataset.adId = adId;
            
            this.showModal('ad-modal');
        } catch (error) {
            console.error('Error editing ad:', error);
            alert('Failed to load advertisement details');
        }
    }

    async saveAd() {
        try {
            const form = document.getElementById('ad-form');
            const mode = form.dataset.mode;
            const adId = form.dataset.adId;
            
            // Get selected locations
            const allLocationsChecked = document.getElementById('ad-location-all').checked;
            let locations = [];
            if (allLocationsChecked) {
                locations = ['all'];
            } else {
                const selectedCheckboxes = document.querySelectorAll('.ad-location-checkbox:checked');
                locations = Array.from(selectedCheckboxes).map(cb => cb.value);
                if (locations.length === 0) {
                    alert('Please select at least one location or "All Locations"');
                    return;
                }
            }
            
            const imageInput = document.getElementById('ad-image-url');
            let imageUrl = '';
            
            // Get existing image URL if editing
            if (mode === 'edit' && adId) {
                const existingAd = this.currentAds.find(a => a.id === adId);
                if (existingAd) {
                    imageUrl = existingAd.imageUrl || '';
                }
            }
            
            // Upload image if a new file is selected
            if (imageInput.files && imageInput.files.length > 0) {
                const file = imageInput.files[0];
                const submitBtn = form.querySelector('button[type="submit"]');
                const originalText = submitBtn.innerHTML;
                submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Uploading image...';
                submitBtn.disabled = true;
                
                const uploadResult = await FirebaseService.uploadImage(file, 'advertisements');
                if (uploadResult.success) {
                    imageUrl = uploadResult.url;
                } else {
                    alert('Failed to upload image: ' + uploadResult.error);
                    submitBtn.innerHTML = originalText;
                    submitBtn.disabled = false;
                    return;
                }
            } else if (mode !== 'edit' && !imageUrl) {
                // New ad must have an image
                alert('Please select an image for the advertisement');
                return;
            }
            
            const adData = {
                title: document.getElementById('ad-title').value.trim(),
                description: document.getElementById('ad-description').value.trim(),
                imageUrl: imageUrl,
                displayOrder: parseInt(document.getElementById('ad-display-order').value) || 1,
                clickUrl: document.getElementById('ad-click-url').value.trim(),
                isActive: document.getElementById('ad-is-active').checked,
                locations: locations
            };

            // Validate required fields
            if (!adData.imageUrl) {
                alert('Image is required');
                return;
            }

            // Show loading
            const submitBtn = form.querySelector('button[type="submit"]');
            const originalText = submitBtn.innerHTML;
            submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Saving...';
            submitBtn.disabled = true;

            let result;
            if (mode === 'edit') {
                result = await FirebaseService.updateAd(adId, adData);
            } else {
                result = await FirebaseService.createAd(adData);
            }

            if (result.success) {
                alert(`Advertisement ${mode === 'edit' ? 'updated' : 'created'} successfully!`);
                this.closeModal('ad-modal');
                this.loadAds(); // Refresh the list
            } else {
                alert(result.error || `Failed to ${mode === 'edit' ? 'update' : 'create'} advertisement`);
            }

        } catch (error) {
            console.error('Error saving ad:', error);
            alert('Failed to save advertisement');
        } finally {
            // Reset button
            const submitBtn = document.getElementById('ad-form').querySelector('button[type="submit"]');
            if (submitBtn) {
                submitBtn.innerHTML = '<i class="fas fa-save"></i> Save Advertisement';
                submitBtn.disabled = false;
            }
        }
    }

    async toggleAdStatus(adId, newStatus) {
        try {
            const result = await FirebaseService.toggleAdStatus(adId, newStatus);
            if (result.success) {
                this.loadAds(); // Refresh the list
            } else {
                alert(result.error || 'Failed to toggle advertisement status');
            }
        } catch (error) {
            console.error('Error toggling ad status:', error);
            alert('Failed to toggle advertisement status');
        }
    }

    async deleteAd(adId) {
        if (!confirm('Are you sure you want to delete this advertisement? This action cannot be undone.')) {
            return;
        }

        try {
            const result = await FirebaseService.deleteAd(adId);
            if (result.success) {
                alert('Advertisement deleted successfully');
                this.loadAds(); // Refresh the list
            } else {
                alert(result.error || 'Failed to delete advertisement');
            }
        } catch (error) {
            console.error('Error deleting ad:', error);
            alert('Failed to delete advertisement');
        }
    }

    previewAd(adId) {
        const ad = this.currentAds.find(a => a.id === adId);
        if (!ad) {
            alert('Advertisement not found');
            return;
        }

        const previewContent = document.getElementById('ad-preview-content');
        previewContent.innerHTML = `
            <div class="ad-preview-item">
                ${ad.imageUrl ? `<img src="${ad.imageUrl}" alt="${ad.title || 'Advertisement'}">` : '<div style="height:200px; background:#f8f9fa; display:flex; align-items:center; justify-content:center; color:#6c757d; border-radius:6px;"><i class="fas fa-image"></i> No image</div>'}
                ${ad.title ? `<h4>${ad.title}</h4>` : ''}
                ${ad.description ? `<p>${ad.description}</p>` : ''}
                <div style="margin-top:1rem; padding-top:1rem; border-top:1px solid #eee; display:flex; justify-content:space-between; align-items:center; font-size:0.9rem; color:#666;">
                    <span>Display Order: ${ad.displayOrder}</span>
                    <span>Status: ${ad.isActive ? '<span style="color:#28a745;">Active</span>' : '<span style="color:#dc3545;">Inactive</span>'}</span>
                </div>
                ${ad.clickUrl ? `<div style="margin-top:0.5rem; font-size:0.9rem; color:#666;"><strong>Click URL:</strong> <a href="${ad.clickUrl}" target="_blank">${ad.clickUrl}</a></div>` : ''}
                <div style="margin-top:0.5rem; font-size:0.9rem; color:#666;">
                    <span style="margin-right:1rem;"><i class="fas fa-eye"></i> ${ad.views || 0} views</span>
                    <span><i class="fas fa-mouse-pointer"></i> ${ad.clickCount || 0} clicks</span>
                </div>
            </div>
        `;
        
        // Store current ad ID for edit button
        const editAdFromPreviewBtn = document.getElementById('edit-ad-from-preview-btn');
        if (editAdFromPreviewBtn) {
            editAdFromPreviewBtn.dataset.adId = adId;
        }
        
        this.showModal('ad-preview-modal');
    }

    // Messaging Functions
    openSendMessageModal(userId) {
        if (!userId) {
            console.error('No user ID provided to open send message modal.');
            alert('Cannot send message: no user selected.');
            return;
        }
        const userName = this.currentUsers.find(user => user.id === userId)?.name || 'Unknown User';
        
        // Set recipient info
        document.getElementById('message-recipient').value = `${userName} (${userId.substring(0, 8)})`;
        
        // Store userId for sending
        const messageModal = document.getElementById('send-message-modal');
        if (messageModal) {
            messageModal.dataset.userId = userId;
        }
        
        // Clear form
        document.getElementById('send-message-form').reset();
        
        // Show modal
        this.showModal('send-message-modal');
    }

    async sendMessage() {
        try {
            const messageModal = document.getElementById('send-message-modal');
            const userId = messageModal?.dataset.userId;
            
            if (!userId) {
                alert('No recipient user found.');
                return;
            }

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
            const result = await FirebaseService.sendMessageToUser(userId, messageData);
            
            if (result.success) {
                // Success
                alert('Message sent successfully!');
                this.closeModal('send-message-modal');
            } else {
                alert(result.error || 'Failed to send message.');
            }
            
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

    sendMessageToUser(userId) { // This function now correctly accepts userId
        this.openSendMessageModal(userId);
    }

    openSendMessageToAllModal() {
        // Clear form
        document.getElementById('send-message-all-form').reset();
        document.getElementById('message-all-recipient').value = 'All Users';
        
        // Hide progress bar
        document.getElementById('send-all-progress').style.display = 'none';
        
        // Show modal
        this.showModal('send-message-all-modal');
    }

    async sendMessageToAllUsers() {
        try {
            const messageData = {
                subject: document.getElementById('message-all-subject').value,
                content: document.getElementById('message-all-content').value,
                type: document.getElementById('message-all-type').value
            };

            // Validate
            if (!messageData.subject.trim() || !messageData.content.trim()) {
                alert('Please fill in all required fields');
                return;
            }

            // Confirm before sending
            const confirmMessage = `Are you sure you want to send this message to ALL users in the system?\n\nSubject: ${messageData.subject}\n\nThis action cannot be undone.`;
            if (!confirm(confirmMessage)) {
                return;
            }

            // Show progress bar
            const progressDiv = document.getElementById('send-all-progress');
            progressDiv.style.display = 'block';
            
            // Show loading
            const submitBtn = document.getElementById('send-all-submit-btn');
            const originalText = submitBtn.innerHTML;
            submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Sending...';
            submitBtn.disabled = true;

            // Progress callback
            const updateProgress = (progress, successCount, failCount, totalUsers) => {
                document.getElementById('progress-percent').textContent = `${progress}%`;
                document.getElementById('progress-bar').style.width = `${progress}%`;
                document.getElementById('progress-stats').textContent = `${successCount + failCount} / ${totalUsers} users`;
                document.getElementById('progress-success').textContent = `✓ ${successCount} sent`;
                document.getElementById('progress-failed').textContent = `✗ ${failCount} failed`;
            };

            // Send message to all users
            const result = await FirebaseService.sendMessageToAllUsers(messageData, updateProgress);
            
            if (result.success) {
                // Success
                alert(`Message sent successfully!\n\nTotal users: ${result.totalUsers}\nSuccessfully sent: ${result.successCount}\nFailed: ${result.failCount}`);
                this.closeModal('send-message-all-modal');
            } else {
                alert(result.error || 'Failed to send message to all users.');
            }
            
        } catch (error) {
            console.error('Error sending message to all users:', error);
            alert('Failed to send message to all users. Please try again.');
        } finally {
            // Reset button
            const submitBtn = document.getElementById('send-all-submit-btn');
            if (submitBtn) {
                submitBtn.innerHTML = '<i class="fas fa-bullhorn"></i> Send to All Users';
                submitBtn.disabled = false;
            }
            // Hide progress bar
            document.getElementById('send-all-progress').style.display = 'none';
        }
    }

    contactReporter() {
        // This would typically open phone dialer or email client
        alert('Contact functionality would be implemented here');
    }
}

// Initialize AdminFeatures immediately
console.log('Initializing AdminFeatures...');
window.adminFeatures = new AdminFeatures();
console.log('AdminFeatures initialized:', window.adminFeatures);

// Also initialize when DOM is loaded as backup
document.addEventListener('DOMContentLoaded', () => {
    if (!window.adminFeatures) {
        console.log('AdminFeatures not found, initializing...');
        window.adminFeatures = new AdminFeatures();
        console.log('AdminFeatures initialized on DOM load:', window.adminFeatures);
    }
}); 