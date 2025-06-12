import streamlit as st
import requests
import json
from datetime import datetime
import os
from typing import List, Dict

# Configuration
API_BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8000")
ADMIN_TOKEN = os.getenv("ADMIN_TOKEN", "your-admin-jwt-token")

# Streamlit page config
st.set_page_config(
    page_title="MedApp Push Admin",
    page_icon="📱",
    layout="wide"
)

# Custom CSS
st.markdown("""
<style>
    .success-box {
        padding: 1rem;
        border-radius: 0.5rem;
        background-color: #d4edda;
        border: 1px solid #c3e6cb;
        color: #155724;
        margin: 1rem 0;
    }
    .error-box {
        padding: 1rem;
        border-radius: 0.5rem;
        background-color: #f8d7da;
        border: 1px solid #f5c6cb;
        color: #721c24;
        margin: 1rem 0;
    }
    .metric-card {
        background-color: #f8f9fa;
        padding: 1rem;
        border-radius: 0.5rem;
        text-align: center;
        border: 1px solid #dee2e6;
    }
</style>
""", unsafe_allow_html=True)

# Session state initialization
if 'sent_notifications' not in st.session_state:
    st.session_state.sent_notifications = []

# Helper functions
def send_api_request(endpoint: str, method: str = "GET", data: Dict = None):
    """Send API request with authentication"""
    headers = {
        "Authorization": f"Bearer {ADMIN_TOKEN}",
        "Content-Type": "application/json"
    }
    
    url = f"{API_BASE_URL}{endpoint}"
    
    try:
        if method == "GET":
            response = requests.get(url, headers=headers)
        elif method == "POST":
            response = requests.post(url, headers=headers, json=data)
        
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        st.error(f"API Error: {str(e)}")
        return None

# Main app
st.title("🏥 MedApp Push Notification Admin")
st.markdown("---")

# Sidebar for settings
with st.sidebar:
    st.header("⚙️ Settings")
    
    # API Status
    st.subheader("API Status")
    if st.button("Check Connection"):
        result = send_api_request("/")
        if result:
            st.success(f"✅ Connected to API v{result.get('version', 'unknown')}")
        else:
            st.error("❌ Cannot connect to API")
    
    st.markdown("---")
    
    # Statistics
    st.subheader("📊 Statistics")
    col1, col2 = st.columns(2)
    with col1:
        st.metric("Sent Today", len(st.session_state.sent_notifications))
    with col2:
        st.metric("Active Users", "N/A")

# Main content area with tabs
tab1, tab2, tab3, tab4 = st.tabs(["📤 Send Push", "💬 Health Messages", "📊 Analytics", "📜 History"])

# Tab 1: Send Push Notification
with tab1:
    st.header("Send Push Notification")
    
    col1, col2 = st.columns([2, 1])
    
    with col1:
        # Notification form
        with st.form("push_form"):
            st.subheader("Notification Details")
            
            title = st.text_input("Title*", placeholder="Emergency Health Alert")
            body = st.text_area("Message Body*", placeholder="Enter your notification message here...", height=100)
            
            # Target audience
            st.subheader("Target Audience")
            target_type = st.radio(
                "Send to:",
                ["All Users", "Specific Community", "Specific Users"]
            )
            
            community_id = None
            user_ids = None
            
            if target_type == "Specific Community":
                community_id = st.selectbox(
                    "Select Community",
                    ["aboriginal_health", "torres_strait", "remote_communities", "urban_indigenous"]
                )
            elif target_type == "Specific Users":
                user_ids_input = st.text_area(
                    "User IDs (one per line)",
                    placeholder="user123\nuser456\nuser789"
                )
                user_ids = [uid.strip() for uid in user_ids_input.split('\n') if uid.strip()]
            
            # Additional data
            st.subheader("Additional Data (Optional)")
            col1_data, col2_data = st.columns(2)
            with col1_data:
                data_key = st.text_input("Data Key", placeholder="action")
            with col2_data:
                data_value = st.text_input("Data Value", placeholder="open_app")
            
            # Priority
            priority = st.select_slider(
                "Priority",
                options=["Low", "Normal", "High", "Urgent"],
                value="Normal"
            )
            
            # Submit button
            submitted = st.form_submit_button("🚀 Send Notification", type="primary", use_container_width=True)
            
            if submitted:
                if not title or not body:
                    st.error("Please fill in all required fields!")
                else:
                    # Prepare notification data
                    notification_data = {
                        "title": title,
                        "body": body,
                        "data": {data_key: data_value} if data_key and data_value else {},
                        "broadcast": target_type == "All Users",
                        "community_id": community_id,
                        "user_ids": user_ids
                    }
                    
                    # Send notification
                    with st.spinner("Sending notification..."):
                        result = send_api_request("/admin/send-push", "POST", notification_data)
                    
                    if result and result.get("status") == "success":
                        st.success("✅ Notification sent successfully!")
                        
                        # Add to history
                        st.session_state.sent_notifications.append({
                            "title": title,
                            "body": body,
                            "timestamp": datetime.now(),
                            "target": target_type,
                            "priority": priority,
                            "result": result
                        })
                        
                        # Show metrics
                        if "fcm_result" in result:
                            fcm = result["fcm_result"]
                            col1_res, col2_res = st.columns(2)
                            with col1_res:
                                st.metric("Success", fcm.get("success_count", 0))
                            with col2_res:
                                st.metric("Failed", fcm.get("failure_count", 0))
                    else:
                        st.error("❌ Failed to send notification")
    
    with col2:
        # Preview
        st.subheader("📱 Preview")
        
        # Mock phone preview
        preview_container = st.container()
        with preview_container:
            st.markdown("""
            <div style="border: 2px solid #333; border-radius: 20px; padding: 20px; background-color: #f0f0f0; max-width: 300px; margin: auto;">
                <div style="background-color: white; border-radius: 10px; padding: 15px; box-shadow: 0 2px 5px rgba(0,0,0,0.1);">
                    <div style="display: flex; align-items: center; margin-bottom: 10px;">
                        <span style="font-size: 20px; margin-right: 10px;">🏥</span>
                        <span style="font-weight: bold;">MedApp</span>
                        <span style="margin-left: auto; color: #666; font-size: 12px;">now</span>
                    </div>
                    <div style="font-weight: bold; margin-bottom: 5px;">{}</div>
                    <div style="color: #666; font-size: 14px;">{}</div>
                </div>
            </div>
            """.format(
                title if title else "Notification Title",
                body[:100] + "..." if body and len(body) > 100 else body if body else "Notification message will appear here..."
            ), unsafe_allow_html=True)

# Tab 2: Health Messages
with tab2:
    st.header("Health Messages")
    
    # Create new health message
    with st.expander("➕ Create New Health Message", expanded=True):
        with st.form("health_message_form"):
            msg_title = st.text_input("Message Title*", placeholder="COVID-19 Vaccination Update")
            msg_content = st.text_area("Message Content*", placeholder="Detailed health information...", height=150)
            msg_community = st.selectbox(
                "Target Community*",
                ["aboriginal_health", "torres_strait", "remote_communities", "urban_indigenous", "all_communities"]
            )
            msg_priority = st.select_slider(
                "Priority",
                options=["normal", "high", "urgent"],
                value="normal"
            )
            
            if st.form_submit_button("📨 Create & Send", type="primary", use_container_width=True):
                if not msg_title or not msg_content:
                    st.error("Please fill in all required fields!")
                else:
                    message_data = {
                        "title": msg_title,
                        "content": msg_content,
                        "community_id": msg_community,
                        "priority": msg_priority
                    }
                    
                    with st.spinner("Creating health message..."):
                        result = send_api_request("/admin/health-message", "POST", message_data)
                    
                    if result and result.get("status") == "success":
                        st.success("✅ Health message created and notifications sent!")
                        st.balloons()
                    else:
                        st.error("❌ Failed to create health message")
    
    # List existing messages
    st.subheader("📋 Recent Health Messages")
    
    # Fetch messages
    messages = send_api_request("/messages")
    
    if messages and "messages" in messages:
        for msg in messages["messages"][:10]:  # Show last 10
            with st.container():
                col1, col2, col3 = st.columns([3, 1, 1])
                with col1:
                    st.markdown(f"**{msg['title']}**")
                    st.caption(msg['content'][:150] + "..." if len(msg['content']) > 150 else msg['content'])
                with col2:
                    priority_colors = {"normal": "🟢", "high": "🟡", "urgent": "🔴"}
                    st.markdown(f"{priority_colors.get(msg['priority'], '⚪')} {msg['priority'].upper()}")
                with col3:
                    if msg.get('created_at'):
                        created_date = datetime.fromisoformat(msg['created_at'].replace('Z', '+00:00'))
                        st.caption(created_date.strftime("%Y-%m-%d %H:%M"))
                st.markdown("---")
    else:
        st.info("No health messages found")

# Tab 3: Analytics
with tab3:
    st.header("Push Notification Analytics")
    
    # Metrics row
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        st.markdown('<div class="metric-card">', unsafe_allow_html=True)
        st.metric("Total Sent", len(st.session_state.sent_notifications))
        st.markdown('</div>', unsafe_allow_html=True)
    
    with col2:
        st.markdown('<div class="metric-card">', unsafe_allow_html=True)
        st.metric("Success Rate", "N/A")
        st.markdown('</div>', unsafe_allow_html=True)
    
    with col3:
        st.markdown('<div class="metric-card">', unsafe_allow_html=True)
        st.metric("Avg. Delivery Time", "N/A")
        st.markdown('</div>', unsafe_allow_html=True)
    
    with col4:
        st.markdown('<div class="metric-card">', unsafe_allow_html=True)
        st.metric("Active Devices", "N/A")
        st.markdown('</div>', unsafe_allow_html=True)
    
    # Charts placeholder
    st.subheader("📈 Trends")
    st.info("Analytics charts will be displayed here once we have more data")

# Tab 4: History
with tab4:
    st.header("Notification History")
    
    if st.session_state.sent_notifications:
        # Sort by timestamp (newest first)
        sorted_notifications = sorted(
            st.session_state.sent_notifications,
            key=lambda x: x['timestamp'],
            reverse=True
        )
        
        for notif in sorted_notifications:
            with st.expander(f"📤 {notif['title']} - {notif['timestamp'].strftime('%Y-%m-%d %H:%M:%S')}"):
                col1, col2 = st.columns([2, 1])
                
                with col1:
                    st.markdown(f"**Title:** {notif['title']}")
                    st.markdown(f"**Body:** {notif['body']}")
                    st.markdown(f"**Target:** {notif['target']}")
                    st.markdown(f"**Priority:** {notif['priority']}")
                
                with col2:
                    if 'result' in notif and 'fcm_result' in notif['result']:
                        fcm = notif['result']['fcm_result']
                        st.metric("Delivered", fcm.get('success_count', 0))
                        st.metric("Failed", fcm.get('failure_count', 0))
    else:
        st.info("No notifications sent yet in this session")

# Footer
st.markdown("---")
st.caption("MedApp Push Notification Admin v1.0.0 | Made with ❤️ for Aboriginal & Torres Strait Islander Communities")