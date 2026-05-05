{
  "current_phase": null,
  "phase_progress": {
    "1": { "started": null, "completed": null },
    "2": { "started": null, "completed": null },
    "3": { "started": null, "completed": null },
    "4": { "started": null, "completed": null },
    "5": { "started": null, "completed": null },
    "6": { "started": null, "completed": null },
    "7": { "started": null, "completed": null },
    "8": { "started": null, "completed": null }
  },
  "requirements_traceability": {
    "1": ["AUTH-01", "AUTH-02", "AUTH-03", "AUTH-04", "AUTH-05", "PLAT-01", "PLAT-02", "PLAT-03", "PLAT-04", "PLAT-05"],
    "2": ["SIGN-01", "SIGN-02", "SIGN-03", "SIGN-04", "SIGN-05", "SPEECH-01", "SPEECH-02", "SPEECH-03", "SPEECH-04"],
    "3": ["AVATAR-01", "AVATAR-02", "AVATAR-03", "AVATAR-04", "AVATAR-05", "SPEECH-02", "SPEECH-03", "SPEECH-04"],
    "4": ["F2F-01", "F2F-02", "F2F-03", "F2F-04", "F2F-05", "F2F-06", "CALL-01", "CALL-02", "CALL-03", "CALL-04", "CALL-05", "CALL-06"],
    "5": ["DICT-01", "DICT-02", "DICT-03", "DICT-04", "DICT-05", "LEARN-01", "LEARN-02", "LEARN-03", "LEARN-04", "LEARN-05", "LEARN-06"],
    "6": ["SOS-01", "SOS-02", "SOS-03", "SOS-04", "SOS-05", "SOS-06", "NOTIF-01", "NOTIF-02", "NOTIF-03", "NOTIF-04", "NOTIF-05", "HISTORY-01", "HISTORY-02", "HISTORY-03", "HISTORY-04", "HISTORY-05"],
    "7": ["ADMIN-01", "ADMIN-02", "ADMIN-03", "ADMIN-04", "ADMIN-05", "ADMIN-06", "ADMIN-07", "ADMIN-08", "ADMIN-09"],
    "8": ["PLAT-01", "PLAT-02", "PLAT-03", "PLAT-04", "PLAT-05"]
  },
  "milestone_notes": {},
  "phase_dependencies": {
    "2": ["1"],
    "3": ["2"],
    "4": ["2", "3", "1"],
    "5": ["2"],
    "6": ["1"],
    "7": ["1", "2", "3", "4", "5", "6"],
    "8": ["1", "2", "3", "4", "5", "6", "7"]
  }
}
