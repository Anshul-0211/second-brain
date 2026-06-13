import { getRemindersNeedingNotification, markReminderNotificationSent } from '../db/queries.js';

export interface NotificationPayload {
  reminderId: string;
  taskName: string;
  dueDate: string;
  itemId: string;
  priority: string;
}

/**
 * Mock notification queue (in production, use Firebase Cloud Messaging)
 */
const notificationQueue: NotificationPayload[] = [];

export async function scheduleReminderNotifications(): Promise<void> {
  console.log('\n📬 [notificationScheduler] Running...');
  
  try {
    // Get reminders due within next 24 hours that haven't been notified
    const reminders = await getRemindersNeedingNotification(24);

    if (reminders.length === 0) {
      console.log('   ✓ No reminders need notification');
      return;
    }

    console.log(`   Found ${reminders.length} reminders needing notification`);

    for (const reminder of reminders) {
      try {
        // Queue notification
        const notification: NotificationPayload = {
          reminderId: reminder.id,
          taskName: reminder.task_name,
          dueDate: reminder.due_date,
          itemId: reminder.item_id,
          priority: reminder.priority,
        };

        notificationQueue.push(notification);

        // Mark as notification sent in database
        await markReminderNotificationSent(reminder.id);

        // Calculate hours until due
        const hoursUntilDue = Math.round(
          (new Date(reminder.due_date).getTime() - Date.now()) / (1000 * 60 * 60)
        );

        console.log(
          `   ✓ Queued: "${reminder.task_name}" (due in ${hoursUntilDue} hours)`
        );
      } catch (error) {
        console.error(
          `   ✗ Failed to process reminder ${reminder.id}:`,
          error
        );
      }
    }

    console.log(
      `   📍 Total queued: ${notificationQueue.length} notifications\n`
    );
  } catch (error) {
    console.error('[notificationScheduler] Error:', error);
  }
}

/**
 * Send all queued notifications (mock implementation)
 * In production, integrate Firebase Cloud Messaging here
 */
export async function sendQueuedNotifications(): Promise<void> {
  if (notificationQueue.length === 0) return;

  console.log(
    `📤 [notificationQueue] Sending ${notificationQueue.length} notifications...`
  );

  while (notificationQueue.length > 0) {
    const notification = notificationQueue.shift();
    if (!notification) break;

    try {
      // TODO: Integrate Firebase Cloud Messaging
      // await firebaseAdmin.messaging().send({
      //   notification: {
      //     title: '📋 Reminder',
      //     body: notification.taskName,
      //   },
      //   data: {
      //     reminderId: notification.reminderId,
      //     itemId: notification.itemId,
      //   },
      //   topic: 'reminders',
      // });

      const daysUntilDue = Math.round(
        (new Date(notification.dueDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24)
      );
      const dueDateStr = new Date(notification.dueDate)
        .toISOString()
        .split('T')[0];

      console.log(
        `   ✓ ${notification.priority.toUpperCase()}: "${notification.taskName}" due ${dueDateStr}`
      );
    } catch (error) {
      console.error(
        `   ✗ Failed to send notification for reminder ${notification.reminderId}:`,
        error
      );
      // Re-queue on failure
      notificationQueue.push(notification);
    }
  }
}

/**
 * Get the notification queue for testing
 */
export function getNotificationQueue(): NotificationPayload[] {
  return [...notificationQueue];
}

/**
 * Clear the notification queue (for testing)
 */
export function clearNotificationQueue(): void {
  notificationQueue.length = 0;
}
