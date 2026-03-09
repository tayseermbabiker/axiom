// Log an action to the immutable activity log
async function logActivity(engagementId, action, targetType, targetId, details = {}) {
  const user = await getCurrentUser();
  if (!user) return;

  await supabaseClient.from('activity_log').insert({
    engagement_id: engagementId,
    user_id: user.id,
    action,
    target_type: targetType,
    target_id: targetId,
    details
  });
}
