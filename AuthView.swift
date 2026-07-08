// AuthView.swift
// Main auth screen – choose Email or Phone login

import SwiftUI

struct AuthView: View {
    @State private var showEmailAuth = false
    @State private var showPhoneAuth = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#FF6B35"), Color(hex: "#FF4757")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo & Tagline
                VStack(spacing: 16) {
                    Image(systemName: "hands.and.sparkles.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                    
                    Text("HelpConnect")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("See a need. Fill a need.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Auth Buttons
                VStack(spacing: 16) {
                    Button {
                        showEmailAuth = true
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Continue with Email")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .foregroundColor(Color(hex: "#FF4757"))
                        .cornerRadius(14)
                    }
                    
                    Button {
                        showPhoneAuth = true
                    } label: {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Continue with Phone")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.5), lineWidth: 1)
                        )
                    }
                    
                    Text("By signing up you agree to our Terms & Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthView()
        }
        .sheet(isPresented: $showPhoneAuth) {
            PhoneAuthView()
        }
    }
}

// MARK: - Email Auth View
struct EmailAuthView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: FirebaseManager
    
    @State private var isSignUp = true
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showPassword = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color(hex: "#FF4757"))
                        
                        Text(isSignUp ? "Create Account" : "Welcome Back")
                            .font(.title.bold())
                        
                        Text(isSignUp ? "Join the community of helpers" : "Login to continue helping")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 30)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        if isSignUp {
                            AuthTextField(
                                icon: "person.fill",
                                placeholder: "Full Name",
                                text: $name
                            )
                        }
                        
                        AuthTextField(
                            icon: "envelope.fill",
                            placeholder: "Email Address",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        
                        AuthSecureField(
                            icon: "lock.fill",
                            placeholder: "Password",
                            text: $password
                        )
                        
                        if isSignUp {
                            AuthSecureField(
                                icon: "lock.fill",
                                placeholder: "Confirm Password",
                                text: $confirmPassword
                            )
                        }
                    }
                    
                    // Error
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Action Button
                    Button {
                        Task { await handleAuth() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(isSignUp ? "Create Account" : "Login")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#FF4757"))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(isLoading)
                    
                    // Toggle
                    Button {
                        withAnimation { isSignUp.toggle() }
                        errorMessage = ""
                    } label: {
                        Text(isSignUp ? "Already have an account? Login" : "New here? Create Account")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#FF4757"))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func handleAuth() async {
        errorMessage = ""
        
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        
        if isSignUp {
            guard !name.isEmpty else {
                errorMessage = "Please enter your name."
                return
            }
            guard password == confirmPassword else {
                errorMessage = "Passwords don't match."
                return
            }
            guard password.count >= 6 else {
                errorMessage = "Password must be at least 6 characters."
                return
            }
        }
        
        isLoading = true
        do {
            if isSignUp {
                try await authManager.signUp(email: email, password: password, name: name)
            } else {
                try await authManager.signIn(email: email, password: password)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Phone Auth View
struct PhoneAuthView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: FirebaseManager
    
    @State private var step: PhoneAuthStep = .enterPhone
    @State private var name = ""
    @State private var phone = ""
    @State private var otp = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var resendTimer = 0
    
    enum PhoneAuthStep { case enterPhone, enterOTP }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Icon
                Image(systemName: step == .enterPhone ? "phone.circle.fill" : "message.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#FF4757"))
                
                VStack(spacing: 8) {
                    Text(step == .enterPhone ? "Enter Phone Number" : "Enter OTP")
                        .font(.title2.bold())
                    
                    Text(step == .enterPhone
                         ? "We'll send a 6-digit code to verify your number"
                         : "Enter the code sent to +91 \(phone)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Fields
                VStack(spacing: 16) {
                    if step == .enterPhone {
                        AuthTextField(
                            icon: "person.fill",
                            placeholder: "Your Name",
                            text: $name
                        )
                        
                        HStack(spacing: 0) {
                            // Country code
                            HStack {
                                Text("🇮🇳 +91")
                                    .fontWeight(.medium)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12, corners: [.topLeft, .bottomLeft])
                            
                            TextField("10-digit mobile number", text: $phone)
                                .keyboardType(.phonePad)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12, corners: [.topRight, .bottomRight])
                        }
                    } else {
                        // OTP field
                        TextField("Enter 6-digit OTP", text: $otp)
                            .keyboardType(.numberPad)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .tracking(10)
                            .onChange(of: otp) { _, new in
                                if new.count > 6 { otp = String(new.prefix(6)) }
                            }
                        
                        if resendTimer > 0 {
                            Text("Resend OTP in \(resendTimer)s")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Button("Resend OTP") {
                                Task { await sendOTP() }
                            }
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#FF4757"))
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // Error
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Action Button
                Button {
                    Task {
                        if step == .enterPhone {
                            await sendOTP()
                        } else {
                            await verifyOTP()
                        }
                    }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(step == .enterPhone ? "Send OTP" : "Verify & Login")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#FF4757"))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(isLoading)
                .padding(.horizontal, 24)
                
                if step == .enterOTP {
                    Button("← Change Number") {
                        withAnimation { step = .enterPhone }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func sendOTP() async {
        guard phone.count == 10, !name.isEmpty else {
            errorMessage = "Please enter your name and a valid 10-digit phone number."
            return
        }
        isLoading = true
        errorMessage = ""
        do {
            try await authManager.sendOTP(phoneNumber: phone)
            withAnimation { step = .enterOTP }
            startResendTimer()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    private func verifyOTP() async {
        guard otp.count == 6 else {
            errorMessage = "Please enter the 6-digit OTP."
            return
        }
        isLoading = true
        errorMessage = ""
        do {
            try await authManager.verifyOTP(otp: otp, name: name)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    private func startResendTimer() {
        resendTimer = 60
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if resendTimer > 0 {
                resendTimer -= 1
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Reusable Auth Components
struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AuthSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @State private var isVisible = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            if isVisible {
                TextField(placeholder, text: $text)
            } else {
                SecureField(placeholder, text: $text)
            }
            
            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
