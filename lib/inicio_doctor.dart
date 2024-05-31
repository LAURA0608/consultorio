import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; 

class InicioDoctorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Inicio Doctor'),
          backgroundColor: Color.fromARGB(255, 6, 159, 75),
        ),
        body: DoctorHome(),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => AuthScreen()),
            );
          },
          child: Icon(Icons.logout),
          backgroundColor: Color.fromARGB(255, 6, 159, 75),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}

class DoctorHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('Consulta Nueva'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ConsultaNuevaScreen()),
            );
          },
        ),
        ListTile(
          title: Text('Solicitud de Citas'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SolicitudCitasScreen()),
            );
          },
        ),
        ListTile(
          title: Text('Pacientes'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PacientesScreen()),
            );
          },
        ),
      ],
    );
  }
}

class ConsultaNuevaScreen extends StatefulWidget {
  @override
  _ConsultaNuevaScreenState createState() => _ConsultaNuevaScreenState();
}

class _ConsultaNuevaScreenState extends State<ConsultaNuevaScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _fecha = DateTime.now();
  String _motivo = '';
  String _nombre = '';
  String _nss = '';
  String _tratamiento = '';

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _fecha) {
      setState(() {
        _fecha = picked;
      });
    }
  }

  void _guardarConsulta() {
    if (_formKey.currentState!.validate()) {
      FirebaseFirestore.instance.collection('pacientes').add({
        'fecha': _fecha.toIso8601String(),
        'motivo': _motivo,
        'nombre': _nombre,
        'nss': _nss,
        'tratamiento': _tratamiento,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Consulta guardada con éxito')),
      );
      _formKey.currentState!.reset(); 
      setState(() {
        _fecha = DateTime.now(); 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Consulta Nueva'),
        backgroundColor: Color.fromARGB(255, 6, 159, 75),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ListTile(
                title: Text('Fecha: ${_fecha.toLocal()}'.split(' ')[0]),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Motivo'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el motivo';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _motivo = value;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _nombre = value;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'NSS'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el NSS';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _nss = value;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Tratamiento'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el tratamiento';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _tratamiento = value;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardarConsulta,
                child: Text('Guardar Consulta'),
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

class SolicitudCitasScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitud de Citas'),
        backgroundColor: Color.fromARGB(255, 6, 159, 75),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('citas').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return SolicitudCitaItem(doc);
            }).toList(),
          );
        },
      ),
    );
  }
}

class SolicitudCitaItem extends StatefulWidget {
  final QueryDocumentSnapshot doc;

  SolicitudCitaItem(this.doc);

  @override
  _SolicitudCitaItemState createState() => _SolicitudCitaItemState();
}

class _SolicitudCitaItemState extends State<SolicitudCitaItem> {
  late String _estado;

  @override
  void initState() {
    super.initState();
    _estado = widget.doc['estado']; 
  }

  void _updateEstado(String? nuevoEstado) {
    if (nuevoEstado != null) {
      setState(() {
        _estado = nuevoEstado;
      });
      FirebaseFirestore.instance
          .collection('citas')
          .doc(widget.doc.id)
          .update({'estado': nuevoEstado});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.doc['nombre']),
      subtitle: Text('${widget.doc['fecha']} ${widget.doc['hora']}'),
      trailing: DropdownButton<String>(
        value: _estado,
        onChanged: _updateEstado,
        items: <String>['Pendiente', 'aceptada', 'atendida', 'rechazada'] 
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }
}

class PacientesScreen extends StatefulWidget {
  @override
  _PacientesScreenState createState() => _PacientesScreenState();
}

class _PacientesScreenState extends State<PacientesScreen> {
  String _searchText = '';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pacientes'),
        backgroundColor: Color.fromARGB(255, 6, 159, 75),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o NSS',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('pacientes')
                  .orderBy('nombre', descending: false) 
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final pacientes = snapshot.data!.docs.where((doc) {
                  final nombre = doc['nombre'].toString().toLowerCase();
                  final nss = doc['nss'].toString().toLowerCase();
                  return nombre.contains(_searchText) || nss.contains(_searchText);
                }).toList();
                return ListView(
                  children: pacientes.map((doc) {
                    return ListTile(
                      title: Text(doc['nombre']),
                      subtitle: Text(doc['nss']),
                      trailing: Text(doc['motivo']),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}









