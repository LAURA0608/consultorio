import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:consultorio/main.dart';

void main() {
  runApp(InicioPacienteScreen());
}

class InicioPacienteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Inicio Paciente'),
          backgroundColor: Color.fromARGB(255, 6, 159, 75),
        ),
        body: PatientHome(),
      ),
    );
  }
}

class PatientHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ListTile(
            title: Text('Opciones'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OpcionesScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => AuthScreen()),
          );
        },
        backgroundColor: Color.fromARGB(255, 6, 159, 75),
        child: Icon(Icons.logout),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class OpcionesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Opciones'),
        backgroundColor: Color.fromARGB(255, 6, 159, 75),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('Médicos'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MedicosScreen()),
              );
            },
          ),
          ListTile(
            title: Text('Historial de Citas'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistorialCitasScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MedicosScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Médicos'),
        backgroundColor: Color.fromARGB(255, 6, 159, 75),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('medicos').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text(doc['nombre']),
                subtitle: Text(
                  'Especialidad: ${doc['especialidad']}\nHorario: ${doc['horario']}',
                ),
                onTap: () async {
                  bool hasPendingAppointment = await _hasPendingAppointment();
                  if (hasPendingAppointment) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tienes una cita pendiente. No puedes agendar otra hasta que sea atendida.'),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HacerCitaScreen(medico: doc),
                      ),
                    );
                  }
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<bool> _hasPendingAppointment() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot query = await FirebaseFirestore.instance
        .collection('citas')
        .where('userId', isEqualTo: userId)
        .where('estado', isEqualTo: 'Pendiente')
        .get();
    return query.docs.isNotEmpty;
  }
}

class HistorialCitasScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Citas'),
        backgroundColor: Color.fromARGB(255, 6, 159, 75),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('citas')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text(doc['nombre']),
                subtitle: Text(doc['fecha'] + ' ' + doc['hora']),
                trailing: Text(doc['estado']),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class HacerCitaScreen extends StatefulWidget {
  final QueryDocumentSnapshot medico;

  HacerCitaScreen({required this.medico});

  @override
  _HacerCitaScreenState createState() => _HacerCitaScreenState();
}

class _HacerCitaScreenState extends State<HacerCitaScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _formKey = GlobalKey<FormState>();

  _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 3)),
    );
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
      });
  }

  _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime)
      setState(() {
        _selectedTime = picked;
      });
  }

  _crearCita() async {
    if (_selectedDate == null || _selectedTime == null) return;

    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    String formattedTime = _selectedTime!.format(context);

    String userId = FirebaseAuth.instance.currentUser!.uid;

    // modificacion examen 
    QuerySnapshot query = await FirebaseFirestore.instance
        .collection('citas')
        .where('medicoId', isEqualTo: widget.medico.id)
        .where('fecha', isEqualTo: formattedDate)
        .where('hora', isEqualTo: formattedTime)
        
        .get();

    if (query.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('La fecha y hora seleccionadas ya están ocupadas. Por favor, selecciona otro horario.'),
        ),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('citas').add({
      'userId': userId,
      'medicoId': widget.medico.id,
      'nombre': widget.medico['nombre'],
      'fecha': formattedDate,
      'hora': formattedTime,
      'estado': 'Pendiente',
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hacer Cita con ${widget.medico['nombre']}'),
        backgroundColor: Color.fromARGB(255, 6, 159, 75),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ListTile(
                title: Text(
                    _selectedDate == null ? 'Seleccionar Fecha' : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              ListTile(
                title: Text(_selectedTime == null ? 'Seleccionar Hora' : _selectedTime!.format(context)),
                trailing: Icon(Icons.access_time),
                onTap: () => _selectTime(context),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _crearCita,
                child: Text('Crear Cita'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 6, 159, 75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
