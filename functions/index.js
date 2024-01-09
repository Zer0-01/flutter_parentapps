const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.updateIsNewAttendance = functions.firestore
  .document('Students/{studentId}/Attendance/{attendanceDate}')
  .onUpdate(async (change, context) => {
    // Get the data of the document before and after the update
    const oldData = change.before.data();
    const newData = change.after.data();

    // Check if the status field is updated
    const statusUpdated = oldData.status !== newData.status;

    // Check if isNewAttendance is currently false
    const isNewAttendanceFalse = oldData.isNewAttendance === false;

    // Check if isNewAttendance is already true
    const isNewAttendanceTrue = newData.isNewAttendance === true;

    // Update the isNewAttendance field to true only if status is updated and isNewAttendance is currently false
    if (statusUpdated && isNewAttendanceFalse && !isNewAttendanceTrue) {
      // Update the isNewAttendance field to true
      return change.after.ref.update({isNewAttendance: true});
    }

    return null;
  });

exports.updateIsNewHomework = functions.firestore
  .document('Homework/{homeworkId}')
  .onWrite(async (change, context) => {
    // Get the data of the document
    const newData = change.after.data();
    const previousData = change.before.data();

    // Check if the document is newly created or updated
    const isNewDocument = !change.before.exists;

    // Check if isNewHomework is currently false
    const isNewHomeworkFalse = previousData ? !previousData.isNewHomework : true;

    // Check if isNewHomework is already true
    const isNewHomeworkTrue = newData ? newData.isNewHomework : false;

    // Update the isNewHomework field to true only if it was previously false
    if (isNewDocument || (isNewHomeworkFalse && !isNewHomeworkTrue)) {
      // Update the isNewHomework field to true
      return change.after.ref.update({isNewHomework: true});
    }

    return null;
  });
