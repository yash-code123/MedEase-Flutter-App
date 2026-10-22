/// Rule-based Health Assistant — mirrors the web app's free, offline chatbot.
/// No external API calls, so it works even if the backend is asleep.
class ChatbotService {
  static const _rules = <List<String>, String>{
    ['appointment', 'book'] :
        'You can book an appointment from the Book Appointment tab — pick a department, choose a doctor, select a slot, and pay via UPI to confirm.',
    ['cancel'] :
        'To cancel an appointment, open My Records → Appointments, tap the appointment, and choose Cancel. Refunds for paid slots are handled by the front desk.',
    ['token', 'queue'] :
        'Your queue token is issued automatically right after payment. You can check your live position under My Records → Appointments.',
    ['bill', 'payment', 'upi'] :
        'All bills are generated automatically after booking or a consultation. You will find them under My Records → Bills, with a printable receipt.',
    ['prescription', 'medicine'] :
        'Your prescriptions appear under My Records → Prescriptions right after your doctor saves them, including dosage and duration.',
    ['lab', 'test', 'report'] :
        'Lab test orders and results show up under My Records → Lab Results. You will be notified here once results are uploaded.',
    ['doctor', 'department'] :
        'You can browse doctors by department on the Book Appointment screen — each profile shows their qualification and consultation fee.',
    ['bed', 'ward', 'admit'] :
        'Bed availability is managed by the admin desk. Please visit reception or ask your doctor if you need ward admission.',
    ['emergency', 'urgent'] :
        'For a medical emergency, please call your local emergency number or go directly to the nearest emergency department — this chatbot cannot handle urgent care.',
    ['hi', 'hello', 'hey'] :
        'Hi! I am the MedEase Health Assistant. Ask me about appointments, bills, prescriptions, lab results, or your queue token.',
  };

  static String reply(String message) {
    final lower = message.toLowerCase();
    for (final entry in _rules.entries) {
      if (entry.key.any((k) => lower.contains(k))) return entry.value;
    }
    return "I'm not sure about that yet, but I can help with appointments, bills, prescriptions, lab results, or your queue token. What would you like to know?";
  }
}
