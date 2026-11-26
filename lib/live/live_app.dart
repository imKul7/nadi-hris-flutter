import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'api.dart';
import '../profile/photo.dart';
import '../profile/details.dart';

class _C {
  static const navy=Color(0xFF12283F);
  static const blue=Color(0xFF245BE8);
  static const red=Color(0xFFE34E54);
  static const canvas=Color(0xFFF6F8FC);
  static const green=Color(0xFF11866B);
  static const grey=Color(0xFF71849A);
  static const line=Color(0xFFE1E8F2);
  static const amber=Color(0xFFB67813);
}

class LiveApp extends StatefulWidget {
  final LiveSession session;
  final VoidCallback onLogout;
  const LiveApp({super.key,required this.session,required this.onLogout});
  @override State<LiveApp> createState()=>_LiveAppState();
}
class _LiveAppState extends State<LiveApp> {
  int tab=0;
  int revision=0;
  void refresh(){if(mounted)setState(()=>revision++);}
  void changeTab(int index){setState(()=>tab=index);}
  void go(Widget page){Navigator.of(context).push(MaterialPageRoute(builder:(_)=>page)).then((_)=>refresh());}
  @override Widget build(BuildContext context){
    final s=widget.session;
    final pages=<Widget>[
      if(s.role=='hrd') _HrdHome(session:s,onOpen:go) else _Dashboard(session:s,onOpen:go,onTab:changeTab),
      _Requests(session:s,onCreate:()=>changeTab(2),revision:revision),
      _Apply(session:s,onSuccess:()=>changeTab(1)),
      _Schedule(session:s,revision:revision),
      _Profile(session:s,onLogout:() async {try{await s.api.call('POST','/api/logout',token:s.token);}catch(_){ }widget.onLogout();}),
    ];
    const labels=['Beranda','Riwayat','Pengajuan','Jadwal','Profil'];
    const icons=[Icons.home_outlined,Icons.history_rounded,Icons.description_outlined,Icons.calendar_month_outlined,Icons.person_outline];
    const active=[Icons.home_rounded,Icons.history_rounded,Icons.description_rounded,Icons.calendar_month_rounded,Icons.person_rounded];
    return Scaffold(backgroundColor:_C.canvas,
      body: SafeArea(child:AnimatedSwitcher(duration:const Duration(milliseconds:230),switchInCurve:Curves.easeOutCubic,
        transitionBuilder:(child,animation)=>FadeTransition(opacity:animation,child:SlideTransition(
          position:Tween<Offset>(begin:const Offset(.035,.012),end:Offset.zero).animate(animation),child:child)),
        child:KeyedSubtree(key:ValueKey('$tab-$revision'),child:pages[tab]))),
      bottomNavigationBar:SafeArea(top:false,child:Container(
        decoration:const BoxDecoration(color:Colors.white,border:Border(top:BorderSide(color:_C.line))),
        padding:const EdgeInsets.fromLTRB(5,5,5,5),height:69,
        child:Row(children:List.generate(5,(i)=>Expanded(child:InkWell(
          key:Key('live_tab_$i'),borderRadius:BorderRadius.circular(14),onTap:()=>changeTab(i),
          child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
            AnimatedContainer(duration:const Duration(milliseconds:210),curve:Curves.easeOut,
              padding:const EdgeInsets.symmetric(horizontal:14,vertical:4),
              decoration:BoxDecoration(color:tab==i?const Color(0xFFE8EFFF):Colors.transparent,borderRadius:BorderRadius.circular(12)),
              child:Icon(tab==i?active[i]:icons[i],size:21,color:tab==i?_C.navy:_C.grey)),
            const SizedBox(height:3),Text(labels[i],style:TextStyle(fontSize:10,fontWeight:tab==i?FontWeight.w800:FontWeight.w500,
              color:tab==i?_C.navy:_C.grey)),
          ]))))))),
    );
  }
}

class _UI {
  static Widget text(String t,{double size=13,Color color=_C.navy,FontWeight weight=FontWeight.w500})=>
    Text(t,style:TextStyle(fontSize:size,color:color,fontWeight:weight,height:1.35));
  static Widget title(String t,{double size=24})=>text(t,size:size,weight:FontWeight.w800);
  static Widget panel(Widget child,{Color color=Colors.white,EdgeInsets? padding})=>Container(width:double.infinity,
    padding:padding??const EdgeInsets.all(17),decoration:BoxDecoration(color:color,borderRadius:BorderRadius.circular(18),
    border:Border.all(color:color==Colors.white?_C.line:color)),child:child);
  static Widget bigButton(String label,VoidCallback? onTap,{IconData? icon,Color bg=_C.blue})=>SizedBox(width:double.infinity,height:48,
    child:FilledButton(onPressed:onTap,style:FilledButton.styleFrom(backgroundColor:bg,
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),child:Row(mainAxisAlignment:MainAxisAlignment.center,
      children:[if(icon!=null)...[Icon(icon,size:18),const SizedBox(width:8)],Text(label,style:const TextStyle(fontWeight:FontWeight.w700))])));
  static Widget stat(String caption,String value,{Color color=_C.blue})=>Expanded(child:panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Icon(Icons.insights_outlined,color:color,size:20),const SizedBox(height:6),title(value,size:23),
    text(caption,size:11,color:_C.grey)])));
  static Widget chip(String name,{Color bg=const Color(0xFFE8EFFF),Color fg=_C.blue})=>Container(
    padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(30)),
    child:text(name,size:11,color:fg,weight:FontWeight.w700));
  static Color statusColor(String status)=> status=='disetujui'?_C.green:status=='ditolak'?_C.red:_C.amber;
  static String statusText(String status)=>switch(status){
    'menunggu_manajer'=>'Menunggu Manajer','menunggu_kepala'=>'Menunggu Kepala Departemen','menunggu_hrd'=>'Menunggu HRD',
    'disetujui'=>'Disetujui','ditolak'=>'Ditolak',_=>status};
  static void toast(BuildContext context,String message){if(!context.mounted)return;ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()..showSnackBar(SnackBar(content:Text(message),behavior:SnackBarBehavior.floating));}
  static Widget loading()=>const Padding(padding:EdgeInsets.all(50),child:Center(child:CircularProgressIndicator()));
  static Widget error(String e,VoidCallback retry)=>panel(Column(children:[const Icon(Icons.error_outline,color:_C.red),const SizedBox(height:8),
    text(e,color:_C.red),TextButton(onPressed:retry,child:const Text('Coba lagi'))]));
}
class _Page extends StatelessWidget {
  final String title,caption;
  final List<Widget> children;
  final Widget? trailing;
  const _Page({required this.title,required this.caption,required this.children}) : trailing = null;
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.fromLTRB(20,24,20,30),children:[
    Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_UI.title(title),
      const SizedBox(height:5),_UI.text(caption,size:12,color:_C.grey)])),if(trailing!=null)trailing!]),
    const SizedBox(height:23),...children]);
}
class _Load extends StatefulWidget {
  final Future<Map<String,dynamic>> Function() get;
  final Widget Function(Map<String,dynamic>) builder;
  final int revision;
  const _Load({required this.get,required this.builder,this.revision=0});
  @override State<_Load> createState()=>_LoadState();
}
class _LoadState extends State<_Load>{
  late Future<Map<String,dynamic>> future;
  @override void initState(){super.initState();future=widget.get();}
  @override void didUpdateWidget(covariant _Load old){super.didUpdateWidget(old);if(old.revision!=widget.revision||old.get!=widget.get)future=widget.get();}
  @override Widget build(BuildContext context)=>FutureBuilder<Map<String,dynamic>>(future:future,builder:(context,s){
    if(s.connectionState!=ConnectionState.done)return _UI.loading();
    if(s.hasError)return _UI.error(s.error.toString(),()=>setState(()=>future=widget.get()));
    return widget.builder(s.data??{});
  });
}
String _time(String? iso){if(iso==null)return '--:--';try{final d=DateTime.parse(iso).toLocal();return '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';}catch(_){return '--:--';}}
Map<String,dynamic> _cast(dynamic value)=>(value as Map).cast<String,dynamic>();
List<Map<String,dynamic>> _rows(dynamic value)=>(value as List? ?? []).map(_cast).toList();

class _Dashboard extends StatefulWidget {
  final LiveSession session;
  final void Function(Widget) onOpen;
  final void Function(int) onTab;
  const _Dashboard({required this.session,required this.onOpen,required this.onTab});
  @override State<_Dashboard> createState()=>_DashboardState();
}
class _DashboardState extends State<_Dashboard>{
  int version=0;
  Future<Map<String,dynamic>> load()async{
    final s=widget.session;
    final today=await s.api.call('GET','/api/attendance/today',token:s.token);
    final dashboard=await s.api.call('GET','/api/dashboard',token:s.token);
    return {'attendance':today['attendance'],'stats':dashboard['stats']};
  }
  @override Widget build(BuildContext context)=>_Load(get:load,revision:version,builder:(data){
    final s=widget.session;final at=data['attendance'];final stats=_cast(data['stats']);
    return _Page(title:'Selamat bekerja,',caption:'Satu ritme. Untuk seluruh tim.',children:[
      _UI.title('${s.name.split(' ').first}.',size:25),const SizedBox(height:12),
      _UI.chip('${_roleName(s.role)} · ${s.department}'),const SizedBox(height:24),
      Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:_C.navy,
        borderRadius:BorderRadius.circular(19),border:const Border(top:BorderSide(color:_C.blue,width:4))),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          _UI.text('PRESENSI HARI INI',size:11,color:const Color(0xFFB9CADA),weight:FontWeight.w700),
          const SizedBox(height:9),_UI.text(at==null?'Belum check-in':'Masuk ${_time(_cast(at)['check_in_at'] as String?)}',
            size:28,color:Colors.white,weight:FontWeight.w800),const SizedBox(height:10),
          _UI.chip(at==null?'Menunggu presensi':(_cast(at)['check_out_at']==null?'Sedang bekerja':'Sudah check-out'),
            bg:const Color(0xFF194F52),fg:const Color(0xFFA5ECD7)),
          const SizedBox(height:18),_UI.bigButton('Buka Presensi GPS',()=>widget.onOpen(_Attendance(session:s)),icon:Icons.my_location),
        ])),const SizedBox(height:22),
      _UI.title('Ringkasan kerja',size:17),const SizedBox(height:12),
      Row(children:[_UI.stat('Presensi hari ini', '${stats['attendance_today']??0}',color:_C.blue),
        const SizedBox(width:10),_UI.stat('Pengajuan menunggu','${stats['pending_requests']??0}',color:_C.red)]),
      const SizedBox(height:22),_UI.title('Aksi cepat',size:17),const SizedBox(height:10),
      _Action(Icons.add_circle_outline,'Buat pengajuan','Cuti, izin, sakit, dan lembur',()=>widget.onTab(2)),
      if(['manajer','kepala_departemen','hrd'].contains(s.role)) ...[
        const SizedBox(height:10),_Action(Icons.fact_check_outlined,'Pusat persetujuan','Keputusan sesuai tingkat otorisasi',
          ()=>widget.onOpen(_Approvals(session:s))),
      ],
      const SizedBox(height:10),_Action(Icons.calendar_today_outlined,'Lihat jadwal','Jadwal shift dari database',()=>widget.onTab(3)),
      const SizedBox(height:14),TextButton.icon(onPressed:()=>setState(()=>version++),icon:const Icon(Icons.refresh),label:const Text('Segarkan data')),
    ]);
  });
}
String _roleName(String role)=>switch(role){'manajer'=>'Manajer Bagian','kepala_departemen'=>'Kepala Departemen','hrd'=>'HRD',_=>'Karyawan'};
class _Action extends StatelessWidget{
  final IconData icon;final String title,desc;final VoidCallback onTap;
  const _Action(this.icon,this.title,this.desc,this.onTap);
  @override Widget build(BuildContext context)=>Material(color:Colors.white,borderRadius:BorderRadius.circular(16),
    child:InkWell(borderRadius:BorderRadius.circular(16),onTap:onTap,child:Container(padding:const EdgeInsets.all(14),
      decoration:BoxDecoration(border:Border.all(color:_C.line),borderRadius:BorderRadius.circular(16)),
      child:Row(children:[Container(width:39,height:39,decoration:BoxDecoration(color:const Color(0xFFEAF0FF),
        borderRadius:BorderRadius.circular(12)),child:Icon(icon,color:_C.blue)),const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_UI.text(title,weight:FontWeight.w700),
          _UI.text(desc,size:11,color:_C.grey)])),const Icon(Icons.chevron_right_rounded,color:_C.grey)]))));
}

class _Attendance extends StatefulWidget{
  final LiveSession session;
  const _Attendance({required this.session});
  @override State<_Attendance> createState()=>_AttendanceState();
}
class _AttendanceState extends State<_Attendance>{
  Position? position;
  Map<String,dynamic>? office,attendance;
  bool busy=false;
  String message='Tekan periksa GPS untuk membaca lokasi secara langsung.';
  @override void initState(){super.initState();load();}
  Future<void> load()async{try{
    final o=await widget.session.api.call('GET','/api/office',token:widget.session.token);
    final a=await widget.session.api.call('GET','/api/attendance/today',token:widget.session.token);
    if(mounted)setState((){office=_cast(o['office']);attendance=a['attendance']==null?null:_cast(a['attendance']);});
  }catch(e){if(mounted)setState(()=>message=e.toString());}}
  Future<void> gps()async{
    setState(()=>busy=true);
    try{
      if(!await Geolocator.isLocationServiceEnabled())throw Exception('Layanan lokasi HP belum aktif');
      var perm=await Geolocator.checkPermission();
      if(perm==LocationPermission.denied)perm=await Geolocator.requestPermission();
      if(perm==LocationPermission.denied||perm==LocationPermission.deniedForever)throw Exception('Izin lokasi belum diberikan');
      final p=await Geolocator.getCurrentPosition(locationSettings:const LocationSettings(accuracy:LocationAccuracy.high,timeLimit:Duration(seconds:20)));
      if(mounted)setState((){position=p;message='Lokasi GPS diperbarui. Akurasi ±${p.accuracy.toStringAsFixed(0)} m.';});
    }catch(e){if(mounted)setState(()=>message=e.toString());}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> action(String type)async{
    if(position==null){_UI.toast(context,'Periksa GPS terlebih dahulu.');return;}
    setState(()=>busy=true);
    try{
      final r=await widget.session.api.call('POST','/api/attendance/$type',token:widget.session.token,body:{
        'latitude':position!.latitude,'longitude':position!.longitude,'accuracy_m':position!.accuracy});
      if(mounted){setState(()=>attendance=_cast(r['attendance']));_UI.toast(context,'${type=='check-in'?'Check-in':'Check-out'} tersimpan di database.');}
    }catch(e){if(mounted)_UI.toast(context,e.toString());}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context){
    final p=position,o=office;
    final dist=p!=null&&o!=null?Geolocator.distanceBetween(p.latitude,p.longitude,
      (o['latitude'] as num).toDouble(),(o['longitude'] as num).toDouble()):null;
    final radius=o==null?350.0:(o['radius_m'] as num).toDouble();
    final allowed=dist!=null&&p!.accuracy<=100&&dist+p.accuracy<=radius;
    return Scaffold(appBar:AppBar(title:const Text('Presensi GPS'),backgroundColor:_C.canvas),
      backgroundColor:_C.canvas,body:ListView(padding:const EdgeInsets.all(20),children:[
        _UI.title('Validasi lokasi kerja'),_UI.text('GPS perangkat • verifikasi juga di server',color:_C.grey,size:12),
        const SizedBox(height:18),Container(height:215,decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),
          gradient:const LinearGradient(colors:[Color(0xFFF1F7FF),Color(0xFFE3EDF7)])),
          child:Stack(alignment:Alignment.center,children:[
            ...List.generate(4,(i)=>Positioned(left:(i+1)*50.0,top:0,bottom:0,child:Container(width:1,color:const Color(0xFFCEDEEC)))),
            ...List.generate(3,(i)=>Positioned(top:(i+1)*50.0,left:0,right:0,child:Container(height:1,color:const Color(0xFFCEDEEC)))),
            Container(width:140,height:140,decoration:BoxDecoration(shape:BoxShape.circle,color:_C.blue.withValues(alpha:.10),border:Border.all(color:_C.blue.withValues(alpha:.48),width:2))),
            const Icon(Icons.location_on_rounded,color:_C.blue,size:42),
            Positioned(bottom:13,left:13,right:13,child:_UI.panel(Row(children:[const Icon(Icons.business_outlined,color:_C.green),
              const SizedBox(width:10),Expanded(child:_UI.text(o == null ? 'Kantor Utama' : (o['name']?.toString() ?? 'Kantor Utama'),size:12,weight:FontWeight.w700)),
              _UI.chip('${radius.toStringAsFixed(0)} m')]),padding:const EdgeInsets.all(10))),
          ])),
        const SizedBox(height:18),_UI.title('Akurasi & keamanan',size:17),const SizedBox(height:11),
        Row(children:[_UI.stat('Jarak ke kantor',dist==null?'--':'${dist.toStringAsFixed(0)} m'),
          const SizedBox(width:10),_UI.stat('Akurasi GPS',p==null?'--':'${p.accuracy.toStringAsFixed(0)} m',color:_C.green)]),
        const SizedBox(height:14),_UI.panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          _UI.chip(allowed?'Lokasi dalam zona':'Belum memenuhi zona',bg:allowed?const Color(0xFFE4F5EE):const Color(0xFFFFF2D9),fg:allowed?_C.green:_C.amber),
          const SizedBox(height:8),_UI.text(message,size:12,color:_C.grey),
        ])),const SizedBox(height:15),
        _UI.bigButton(busy?'Memproses...':'Periksa GPS perangkat',busy?null:gps,icon:Icons.gps_fixed),
        const SizedBox(height:10),_UI.bigButton('Check-in',busy||!allowed||attendance!=null?null:()=>action('check-in'),icon:Icons.login),
        const SizedBox(height:10),_UI.bigButton('Check-out',busy||!allowed||attendance==null||attendance!['check_out_at']!=null?null:()=>action('check-out'),icon:Icons.logout,bg:_C.navy),
        const SizedBox(height:15),_UI.text('Zona kantor contoh belum diverifikasi untuk pemakaian nyata. Akurasi GPS tidak membuktikan anti-spoofing.',size:11,color:_C.grey),
      ]));
  }
}

class _Apply extends StatefulWidget {
  final LiveSession session;final VoidCallback onSuccess;
  const _Apply({required this.session,required this.onSuccess});
  @override State<_Apply> createState()=>_ApplyState();
}
class _ApplyState extends State<_Apply>{
  String kind='cuti';DateTime from=DateTime.now(),to=DateTime.now();bool busy=false;
  final reason=TextEditingController();
  @override void dispose(){reason.dispose();super.dispose();}
  Future<void> date(bool start)async{
    final result=await showDatePicker(context:context,initialDate:start?from:to,
      firstDate:DateTime(2024),lastDate:DateTime(2035));
    if(result!=null)setState((){if(start){from=result;if(to.isBefore(from))to=from;}else{to=result;}});
  }
  Future<void> send()async{
    if(reason.text.trim().length<8){_UI.toast(context,'Alasan minimal 8 karakter.');return;}
    if(to.isBefore(from)){_UI.toast(context,'Tanggal selesai tidak boleh mendahului tanggal mulai.');return;}
    setState(()=>busy=true);
    String fmt(DateTime d)=>'${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
    try{
      await widget.session.api.call('POST','/api/requests',token:widget.session.token,body:{
        'kind':kind,'start_date':fmt(from),'end_date':fmt(to),'reason':reason.text.trim()});
      if(mounted){_UI.toast(context,'Pengajuan tersimpan, silakan lihat Riwayat.');reason.clear();widget.onSuccess();}
    }catch(e){if(mounted)_UI.toast(context,e.toString());}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>_Page(title:'Pengajuan baru',caption:'Cuti, izin, sakit, dan lembur',children:[
    _UI.panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      _UI.title('Jenis pengajuan',size:15),const SizedBox(height:12),Wrap(spacing:8,runSpacing:8,
        children:['cuti','izin','sakit','lembur'].map((k)=>ChoiceChip(label:Text(k[0].toUpperCase()+k.substring(1)),selected:kind==k,
          selectedColor:const Color(0xFFDFE9FF),onSelected:(_)=>setState(()=>kind=k))).toList()),
      const SizedBox(height:19),_UI.title('Tanggal mulai',size:13),const SizedBox(height:8),
      _DateRow(date:from,onTap:()=>date(true)),const SizedBox(height:14),_UI.title('Tanggal selesai',size:13),
      const SizedBox(height:8),_DateRow(date:to,onTap:()=>date(false)),const SizedBox(height:14),
      _UI.title('Alasan',size:13),const SizedBox(height:8),TextField(controller:reason,maxLines:4,maxLength:1000,
        decoration:InputDecoration(hintText:'Jelaskan keperluan Anda secara singkat',filled:true,fillColor:_C.canvas,
          border:OutlineInputBorder(borderRadius:BorderRadius.circular(13),borderSide:const BorderSide(color:_C.line)))),
    ])),const SizedBox(height:16),_UI.bigButton(busy?'Mengirim...':'Kirim Pengajuan',busy?null:send,icon:Icons.send_outlined),
    const SizedBox(height:12),_UI.text('Status awal masuk ke alur persetujuan manajer dan kepala departemen, bukan persetujuan otomatis.',color:_C.grey,size:11),
  ]);
}
class _DateRow extends StatelessWidget{
  final DateTime date;final VoidCallback onTap;
  const _DateRow({required this.date,required this.onTap});
  @override Widget build(BuildContext context)=>_Action(Icons.event_outlined,
    '${date.day.toString().padLeft(2,'0')}-${date.month.toString().padLeft(2,'0')}-${date.year}',
    'Ketuk untuk memilih tanggal',onTap);
}

class _Requests extends StatefulWidget{
  final LiveSession session;final VoidCallback onCreate;final int revision;
  const _Requests({required this.session,required this.onCreate,this.revision=0});
  @override State<_Requests> createState()=>_RequestsState();
}
class _RequestsState extends State<_Requests>{String filter='Semua';int version=0;
  Future<Map<String,dynamic>> fetch()=>widget.session.api.call('GET','/api/requests',token:widget.session.token);
  @override Widget build(BuildContext context)=>_Load(get:fetch,revision:version+widget.revision,builder:(data){
    final rows=_rows(data['requests']);
    final visible=filter=='Semua'?rows:rows.where((r)=>filter=='Menunggu'?r['status'].toString().startsWith('menunggu'):r['status']==filter.toLowerCase()).toList();
    return _Page(title:'Pengajuan',caption:'Riwayat dan transparansi keputusan',children:[
      Wrap(spacing:6,runSpacing:6,children:['Semua','Menunggu','Disetujui','Ditolak'].map((f)=>ChoiceChip(label:Text(f),
        selected:filter==f,selectedColor:const Color(0xFFDEE9FF),onSelected:(_)=>setState(()=>filter=f))).toList()),
      const SizedBox(height:21),
      if(visible.isEmpty)_UI.panel(_UI.text('Belum ada pengajuan untuk filter ini.',color:_C.grey))
      else ...visible.map((r)=>Padding(padding:const EdgeInsets.only(bottom:10),child:_UI.panel(Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:_UI.text(r['kind'].toString().toUpperCase(),weight:FontWeight.w800)),
          _UI.chip(_UI.statusText(r['status'].toString()),fg:_UI.statusColor(r['status'].toString()),bg:_UI.statusColor(r['status'].toString()).withValues(alpha:.10))]),
          const SizedBox(height:8),_UI.text('${r['start_date']} s.d. ${r['end_date']}',size:12,color:_C.grey),
          const SizedBox(height:8),_UI.text(r['reason'].toString(),size:12),
        ])))),
      const SizedBox(height:14),_UI.bigButton('Buat pengajuan baru',widget.onCreate,icon:Icons.add_rounded),
      TextButton(onPressed:()=>setState(()=>version++),child:const Text('Segarkan daftar')),
    ]);
  });
}

class _Schedule extends StatefulWidget{
  final LiveSession session;final int revision;
  const _Schedule({required this.session,this.revision=0});
  @override State<_Schedule> createState()=>_ScheduleState();
}
class _ScheduleState extends State<_Schedule>{int v=0;
  Future<Map<String,dynamic>> load()=>widget.session.api.call('GET','/api/schedules',token:widget.session.token);
  @override Widget build(BuildContext context)=>_Load(get:load,revision:widget.revision+v,builder:(d){
    final rows=_rows(d['schedules']);
    return _Page(title:'Jadwal kerja',caption:'Shift kerja terhubung database',children:[
      _UI.panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_UI.chip('JADWAL SHIFT',bg:const Color(0xFFDEE9FF)),
        const SizedBox(height:12),_UI.title('${rows.length} jadwal tercatat',size:20),
        const SizedBox(height:5),_UI.text('Ditetapkan oleh HRD',size:12,color:_C.grey)])),
      const SizedBox(height:17),if(rows.isEmpty)_UI.panel(_UI.text('Belum ada jadwal. Hubungi HRD.',color:_C.grey))
      else ...rows.map((r)=>Padding(padding:const EdgeInsets.only(bottom:9),child:_UI.panel(Row(children:[
        Container(width:4,height:46,decoration:BoxDecoration(color:_C.blue,borderRadius:BorderRadius.circular(4))),
        const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          _UI.text(r['work_date'].toString(),size:11,color:_C.grey),const SizedBox(height:5),_UI.text(r['shift_name'].toString(),weight:FontWeight.w800)])),
        _UI.text('${r['start_time']}–${r['end_time']}',size:11,color:_C.blue),
      ])))),TextButton(onPressed:()=>setState(()=>v++),child:const Text('Segarkan jadwal')),
    ]);
  });
}

class _Approvals extends StatefulWidget{
  final LiveSession session;const _Approvals({required this.session});
  @override State<_Approvals> createState()=>_ApprovalsState();
}
class _ApprovalsState extends State<_Approvals>{int v=0;bool busy=false;
  Future<Map<String,dynamic>> load()=>widget.session.api.call('GET','/api/approvals',token:widget.session.token);
  Future<void> decide(int id,bool approve)async{
    setState(()=>busy=true);
    try{await widget.session.api.call('POST','/api/requests/$id/${approve?'approve':'reject'}',token:widget.session.token,body:{'note':''});
      if(mounted){_UI.toast(context,approve?'Disetujui untuk tahap ini':'Pengajuan ditolak');setState(()=>v++);}}
    catch(e){if(mounted)_UI.toast(context,e.toString());}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:_C.canvas,appBar:AppBar(title:const Text('Pusat persetujuan'),backgroundColor:_C.canvas),
    body:_Load(get:load,revision:v,builder:(d){final rows=_rows(d['requests']);return _Page(
      title:'Pusat persetujuan',caption:_roleName(widget.session.role),children:[
        _UI.panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_UI.text('MENUNGGU KEPUTUSAN',size:11,color:_C.grey),
          const SizedBox(height:10),_UI.title('${rows.length.toString().padLeft(2,'0')} pengajuan',size:25)])),
        const SizedBox(height:17),if(rows.isEmpty)_UI.panel(_UI.text('Tidak ada pengajuan yang memerlukan keputusan Anda.')),
        ...rows.map((r)=>Padding(padding:const EdgeInsets.only(bottom:12),child:_UI.panel(Column(
          crossAxisAlignment:CrossAxisAlignment.start,children:[_UI.title(r['employee_name'].toString(),size:16),
          const SizedBox(height:5),_UI.text('${r['kind']} · ${r['start_date']} — ${r['end_date']}',size:12,color:_C.grey),
          const SizedBox(height:9),_UI.text(r['reason'].toString(),size:12),const SizedBox(height:14),
          Row(children:[Expanded(child:_UI.bigButton('Tolak',busy?null:()=>decide(r['id'] as int,false),bg:_C.red)),
            const SizedBox(width:9),Expanded(child:_UI.bigButton('Setujui',busy?null:()=>decide(r['id'] as int,true)))])])))),
      ]); }));
}

class _HrdHome extends StatefulWidget {
  final LiveSession session;final void Function(Widget) onOpen;
  const _HrdHome({required this.session,required this.onOpen});
  @override State<_HrdHome> createState()=>_HrdHomeState();
}
class _HrdHomeState extends State<_HrdHome>{int rev=0;
  Future<Map<String,dynamic>> load()=>widget.session.api.call('GET','/api/dashboard',token:widget.session.token);
  @override Widget build(BuildContext context)=>_Load(get:load,revision:rev,builder:(d){
    final stats=_cast(d['stats']);
    return _Page(title:'Operasional HRD',caption:'Pantau tim, lokasi, dan penjadwalan',children:[
      Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:_C.navy,borderRadius:BorderRadius.circular(18)),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_UI.text('TENAGA KERJA AKTIF',color:const Color(0xFFBED0E2),size:11),
        const SizedBox(height:8),_UI.text('${stats['active_staff']??0}',color:Colors.white,size:38,weight:FontWeight.w900),
        const SizedBox(height:6),_UI.chip('${stats['departments']??0} Divisi',bg:const Color(0xFF20505A),fg:const Color(0xFFADE8D5))])),
      const SizedBox(height:24),_UI.title('Kelola sistem',size:17),const SizedBox(height:13),
      _Action(Icons.people_outline,'Data karyawan','Lihat & tambah akun karyawan',()=>widget.onOpen(_Staff(session:widget.session))),
      const SizedBox(height:10),_Action(Icons.location_on_outlined,'Lokasi Geofencing','Koordinat kantor dan radius',()=>widget.onOpen(_OfficeAdmin(session:widget.session))),
      const SizedBox(height:10),_Action(Icons.calendar_month_outlined,'Shift & Jadwal','Penugasan shift ke karyawan',()=>widget.onOpen(_ShiftAdmin(session:widget.session))),
      const SizedBox(height:10),_Action(Icons.fact_check_outlined,'Persetujuan HRD','Permohonan kepala departemen',()=>widget.onOpen(_Approvals(session:widget.session))),
      const SizedBox(height:10),_Action(Icons.insights_outlined,'Audit dan laporan','Log aktivitas sistem',()=>widget.onOpen(_Audit(session:widget.session))),
      const SizedBox(height:12),TextButton.icon(onPressed:()=>setState(()=>rev++),icon:const Icon(Icons.refresh),label:const Text('Segarkan dashboard')),
    ]);
  });
}
class _Staff extends StatefulWidget{final LiveSession session;const _Staff({required this.session});@override State<_Staff> createState()=>_StaffState();}
class _StaffState extends State<_Staff>{int v=0;
  void addUser(){showDialog(context:context,builder:(ctx)=>_NewStaff(session:widget.session,onDone:(){Navigator.pop(ctx);setState(()=>v++);}));}
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:_C.canvas,appBar:AppBar(title:const Text('Data karyawan'),backgroundColor:_C.canvas),
    body:_Load(revision:v,get:()=>widget.session.api.call('GET','/api/staff',token:widget.session.token),builder:(d){
      final rows=_rows(d['staff']);return _Page(title:'Tim aktif',caption:'Akun dan pembagian peran',children:[
        _UI.bigButton('Tambah karyawan',addUser,icon:Icons.person_add_alt_1_outlined),const SizedBox(height:15),
        ...rows.map((r)=>Padding(padding:const EdgeInsets.only(bottom:10),child:_UI.panel(Row(children:[
          CircleAvatar(backgroundColor:const Color(0xFFE8EFFF),child:_UI.text(r['name'].toString().substring(0,1),color:_C.blue)),
          const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            _UI.text(r['name'].toString(),weight:FontWeight.w700),
            _UI.text('${r['employee_id']} · ${_roleName(r['role'].toString())}',size:11,color:_C.grey)]))])))),
      ]); }));
}
class _NewStaff extends StatefulWidget{
  final LiveSession session;final VoidCallback onDone;const _NewStaff({required this.session,required this.onDone});
  @override State<_NewStaff> createState()=>_NewStaffState();
}
class _NewStaffState extends State<_NewStaff>{
  final id=TextEditingController(),name=TextEditingController(),email=TextEditingController(),pass=TextEditingController();
  String role='karyawan';int dept=1;bool busy=false;
  @override void dispose(){id.dispose();name.dispose();email.dispose();pass.dispose();super.dispose();}
  Future<void> save()async{setState(()=>busy=true);try{
    await widget.session.api.call('POST','/api/staff',token:widget.session.token,body:{'employee_id':id.text,
      'name':name.text,'email':email.text,'password':pass.text,'role':role,'department_id':dept});
    if(mounted)widget.onDone();
  }catch(e){if(mounted)_UI.toast(context,e.toString());}finally{if(mounted)setState(()=>busy=false);}}
  @override Widget build(BuildContext context)=>AlertDialog(title:const Text('Tambah karyawan'),content:SingleChildScrollView(child:
    SizedBox(width:310,child:Column(mainAxisSize:MainAxisSize.min,children:[
      for(final pair in [(id,'ID Karyawan'),(name,'Nama'),(email,'Email'),(pass,'Password minimal 10 karakter')])...[
        TextField(controller:pair.$1,obscureText:identical(pair.$1,pass),decoration:InputDecoration(labelText:pair.$2)),const SizedBox(height:9)],
      DropdownButtonFormField<String>(initialValue:role,items:['karyawan','manajer','kepala_departemen','hrd']
        .map((r)=>DropdownMenuItem(value:r,child:Text(_roleName(r)))).toList(),onChanged:(r)=>setState(()=>role=r??role)),
      const SizedBox(height:10),DropdownButtonFormField<int>(initialValue:dept,items:const [
        DropdownMenuItem(value:1,child:Text('Quality Control')),DropdownMenuItem(value:2,child:Text('Production')),
        DropdownMenuItem(value:3,child:Text('Finance')),DropdownMenuItem(value:4,child:Text('Human Resources'))],
        onChanged:(v)=>setState(()=>dept=v??dept)),
    ]))),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Batal')),
      FilledButton(onPressed:busy?null:save,child:const Text('Simpan'))]);
}
class _OfficeAdmin extends StatefulWidget{final LiveSession session;const _OfficeAdmin({required this.session});@override State<_OfficeAdmin> createState()=>_OfficeAdminState();}
class _OfficeAdminState extends State<_OfficeAdmin>{
  final name=TextEditingController(),lat=TextEditingController(),lon=TextEditingController(),radius=TextEditingController();
  bool ready=false,busy=false;
  @override void dispose(){name.dispose();lat.dispose();lon.dispose();radius.dispose();super.dispose();}
  Future<Map<String,dynamic>> load()async{final d=await widget.session.api.call('GET','/api/office',token:widget.session.token);
    if(!ready){final x=_cast(d['office']);name.text=x['name'].toString();lat.text=x['latitude'].toString();
      lon.text=x['longitude'].toString();radius.text=x['radius_m'].toString();ready=true;}return d;}
  Future<void> save()async{setState(()=>busy=true);
    try{await widget.session.api.call('PATCH','/api/office',token:widget.session.token,body:{
      'name':name.text,'latitude':double.parse(lat.text),'longitude':double.parse(lon.text),'radius_m':double.parse(radius.text)});
      if(mounted)_UI.toast(context,'Zona kantor disimpan di database.');
    }catch(e){if(mounted)_UI.toast(context,e.toString());}finally{if(mounted)setState(()=>busy=false);}}
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:_C.canvas,appBar:AppBar(title:const Text('Zona Geofencing'),backgroundColor:_C.canvas),
    body:_Load(get:load,builder:(_)=>_Page(title:'Lokasi kantor',caption:'Atur radius dan titik referensi',children:[
      for(final p in [(name,'Nama kantor'),(lat,'Latitude'),(lon,'Longitude'),(radius,'Radius (meter)')])...[
        TextField(controller:p.$1,decoration:InputDecoration(labelText:p.$2)),const SizedBox(height:13)],
      _UI.bigButton(busy?'Menyimpan...':'Simpan konfigurasi',busy?null:save),const SizedBox(height:15),
      _UI.text('PERINGATAN: koordinat awal adalah titik contoh studi kasus. Ganti dengan titik kantor yang terverifikasi sebelum penggunaan nyata.',size:11,color:_C.red)])));
}
class _ShiftAdmin extends StatefulWidget{final LiveSession session;const _ShiftAdmin({required this.session});@override State<_ShiftAdmin> createState()=>_ShiftAdminState();}
class _ShiftAdminState extends State<_ShiftAdmin>{
  int? selectedUser;int selectedShift=1;DateTime day=DateTime.now();bool busy=false;
  Future<Map<String,dynamic>> load()async{final a=await widget.session.api.call('GET','/api/staff',token:widget.session.token);
    final b=await widget.session.api.call('GET','/api/shifts',token:widget.session.token);return {'staff':a['staff'],'shifts':b['shifts']};}
  Future<void> save()async{if(selectedUser==null)return;setState(()=>busy=true);try{
    final date='${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
    await widget.session.api.call('POST','/api/schedules/assign',token:widget.session.token,body:{'user_id':selectedUser,'shift_id':selectedShift,'work_date':date});
    if(mounted)_UI.toast(context,'Jadwal tersimpan di database');
  }catch(e){if(mounted)_UI.toast(context,e.toString());}finally{if(mounted)setState(()=>busy=false);}}
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:_C.canvas,appBar:AppBar(title:const Text('Penugasan shift'),backgroundColor:_C.canvas),
    body:_Load(get:load,builder:(d){final staff=_rows(d['staff']),shifts=_rows(d['shifts']);return _Page(
      title:'Atur jadwal',caption:'Penugasan berbasis data karyawan',children:[
        _UI.panel(Column(children:[DropdownButtonFormField<int>(initialValue:selectedUser,decoration:const InputDecoration(labelText:'Karyawan'),
          items:staff.map((u)=>DropdownMenuItem(value:u['id'] as int,child:Text(u['name'].toString()))).toList(),onChanged:(v)=>setState(()=>selectedUser=v)),
          const SizedBox(height:15),DropdownButtonFormField<int>(initialValue:selectedShift,
          decoration:const InputDecoration(labelText:'Shift'),items:shifts.map((s)=>DropdownMenuItem(value:s['id'] as int,
            child:Text('${s['name']} (${s['start_time']}–${s['end_time']})'))).toList(),onChanged:(v)=>setState(()=>selectedShift=v??1)),
          const SizedBox(height:13),_DateRow(date:day,onTap:()async{final d=await showDatePicker(context:context,initialDate:day,
            firstDate:DateTime(2024),lastDate:DateTime(2035));if(d!=null)setState(()=>day=d);}),
          const SizedBox(height:18),_UI.bigButton(busy?'Menyimpan...':'Tetapkan shift',busy||selectedUser==null?null:save)])),
      ]); }));
}
class _Audit extends StatelessWidget {final LiveSession session;const _Audit({required this.session});
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:_C.canvas,appBar:AppBar(title:const Text('Log aktivitas'),backgroundColor:_C.canvas),
    body:_Load(get:()=>session.api.call('GET','/api/audit',token:session.token),builder:(d){final rows=_rows(d['logs']);
      return _Page(title:'Audit trail',caption:'Riwayat tindakan pada sistem',children:[
        if(rows.isEmpty)_UI.panel(_UI.text('Belum ada aktivitas')),
        ...rows.map((r)=>Padding(padding:const EdgeInsets.only(bottom:9),child:_UI.panel(Row(children:[
          const Icon(Icons.history_toggle_off,color:_C.blue),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
            children:[_UI.text(r['action'].toString(),weight:FontWeight.w700),
              _UI.text('${r['entity']} • ${r['created_at']}',size:10,color:_C.grey)]))])))),
      ]); }));
}
class _Profile extends StatefulWidget {
  final LiveSession session;
  final VoidCallback onLogout;
  const _Profile({required this.session, required this.onLogout});

  @override
  State<_Profile> createState() => _ProfileState();
}

class _ProfileState extends State<_Profile> {
  bool savingPhoto = false;

  Future<void> _saveAvatar(String? avatar) async {
    if (savingPhoto) return;
    setState(() => savingPhoto = true);
    try {
      final result = await widget.session.api.call(
        'PATCH',
        '/api/me/avatar',
        token: widget.session.token,
        body: {'avatar_data': avatar},
      );
      if (!mounted) return;
      widget.session.user
        ..clear()
        ..addAll((result['user'] as Map).cast<String, dynamic>());
      setState(() {});
      _UI.toast(context, avatar == null
          ? 'Foto profil berhasil dihapus.'
          : 'Foto profil tersimpan di database NADI.');
    } catch (error) {
      if (mounted) _UI.toast(context, error.toString());
    } finally {
      if (mounted) setState(() => savingPhoto = false);
    }
  }

  Future<void> _pickAvatar() async {
    if (savingPhoto) return;
    try {
      final photo = await chooseProfilePhoto();
      if (photo != null && mounted) await _saveAvatar(photo);
    } catch (error) {
      if (mounted) _UI.toast(context, error.toString());
    }
  }

  void _showPersonal() {
    final user = widget.session.user;
    showProfileSheet(context, title: 'Data pribadi', children: [
      ProfileDetailRow(label: 'Nama lengkap', value: widget.session.name),
      ProfileDetailRow(label: 'ID karyawan', value: (user['employee_id'] ?? '-').toString()),
      ProfileDetailRow(label: 'Email', value: (user['email'] ?? '-').toString()),
      ProfileDetailRow(label: 'Role', value: _roleName(widget.session.role)),
      ProfileDetailRow(label: 'Departemen', value: widget.session.department),
      const Text(
        'Informasi diambil dari database NADI. Perubahan identitas dilakukan oleh HRD.',
        style: TextStyle(color: _C.grey, fontSize: 12),
      ),
    ]);
  }

  void _showPreferences() {
    showProfileSheet(context, title: 'Preferensi profil', children: [
      StatefulBuilder(
        builder: (sheetContext, updateSheet) => Column(
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tampilkan ID karyawan'),
              subtitle: const Text('Tampilkan ID pada kartu profil'),
              value: widget.session.showEmployeeId,
              onChanged: (v) {
                widget.session.showEmployeeId = v;
                updateSheet(() {});
                setState(() {});
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tampilkan departemen'),
              subtitle: const Text('Tampilkan departemen di kartu profil'),
              value: widget.session.showDepartment,
              onChanged: (v) {
                widget.session.showDepartment = v;
                updateSheet(() {});
                setState(() {});
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Preferensi tampilan berlaku selama sesi login ini. Foto profil disimpan terpisah di database.',
        style: TextStyle(color: _C.grey, fontSize: 12),
      ),
    ]);
  }

  Future<void> _showPasswordChange() async {
    final currentPassword = TextEditingController();
    final newPassword = TextEditingController();
    bool saving = false;
    try {
      await showProfileSheet(context, title: 'Ubah kata sandi', children: [
        StatefulBuilder(
          builder: (sheetContext, updateSheet) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('live_current_password'),
                controller: currentPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Kata sandi saat ini',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 13),
              TextField(
                key: const Key('live_new_password'),
                controller: newPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Kata sandi baru (minimal 10 karakter)',
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
              ),
              const SizedBox(height: 16),
              _UI.bigButton(
                saving ? 'Menyimpan...' : 'Simpan kata sandi',
                saving ? null : () async {
                  if (currentPassword.text.isEmpty || newPassword.text.length < 10) {
                    _UI.toast(sheetContext, 'Isi password lama dan password baru minimal 10 karakter.');
                    return;
                  }
                  updateSheet(() => saving = true);
                  try {
                    await widget.session.api.call(
                      'POST',
                      '/api/me/password',
                      token: widget.session.token,
                      body: {
                        'current_password': currentPassword.text,
                        'new_password': newPassword.text,
                      },
                    );
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                    if (mounted) _UI.toast(context, 'Kata sandi berhasil diganti.');
                  } catch (error) {
                    if (sheetContext.mounted) _UI.toast(sheetContext, error.toString());
                  } finally {
                    if (sheetContext.mounted) updateSheet(() => saving = false);
                  }
                },
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 10),
              const Text(
                'Setelah diganti, sesi di perangkat lain dinonaktifkan. Jangan bagikan kata sandi.',
                style: TextStyle(color: _C.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ]);
    } finally {
      currentPassword.dispose();
      newPassword.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final data = session.user['avatar_data'] as String?;
    return _Page(
      title: 'Profil',
      caption: 'Identitas dan akses akun Anda',
      children: [
        _UI.panel(
          Row(children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                profileAvatar(name: session.name, data: data, radius: 36),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Material(
                    color: _C.blue,
                    shape: const CircleBorder(),
                    child: IconButton(
                      key: const Key('live_avatar_edit'),
                      tooltip: 'Tambah atau ganti foto profil',
                      onPressed: savingPhoto ? null : _pickAvatar,
                      icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 17),
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UI.title(session.name, size: 16),
                if (session.showDepartment)
                  _UI.text(
                    _roleName(session.role) + ' · ' + session.department,
                    size: 12,
                    color: _C.grey,
                  )
                else
                  _UI.text(_roleName(session.role), size: 12, color: _C.grey),
                if (session.showEmployeeId) ...[
                  const SizedBox(height: 7),
                  _UI.chip((session.user['employee_id'] ?? '-').toString()),
                ],
                const SizedBox(height: 6),
                _UI.text('Foto profil opsional', size: 11, color: _C.blue),
              ],
            )),
          ]),
        ),
        if (savingPhoto) ...[
          const SizedBox(height: 9),
          const Center(child: CircularProgressIndicator()),
        ],
        if (data != null) ...[
          const SizedBox(height: 5),
          TextButton.icon(
            key: const Key('live_avatar_remove'),
            onPressed: savingPhoto ? null : () => _saveAvatar(null),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Hapus foto profil'),
          ),
        ],
        const SizedBox(height: 24),
        _UI.title('Pengaturan akun', size: 17),
        const SizedBox(height: 12),
        _Action(
          Icons.person_outline,
          'Data pribadi',
          'Informasi dari database NADI',
          _showPersonal,
        ),
        const SizedBox(height: 10),
        _Action(
          Icons.security_outlined,
          'Keamanan akun',
          'Ubah kata sandi akun',
          _showPasswordChange,
        ),
        const SizedBox(height: 10),
        _Action(
          Icons.tune_outlined,
          'Preferensi',
          'Tampilan informasi profil',
          _showPreferences,
        ),
        const SizedBox(height: 10),
        _Action(
          Icons.help_outline,
          'Bantuan & dukungan',
          'Panduan penggunaan fitur',
          () => showProfileSheet(
            context,
            title: 'Bantuan & dukungan',
            children: [profileHelpContent()],
          ),
        ),
        const SizedBox(height: 26),
        _UI.bigButton(
          'Keluar',
          widget.onLogout,
          icon: Icons.logout,
          bg: _C.navy,
        ),
      ],
    );
  }
}
