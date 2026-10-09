# This section is combined with the existing private museum harness.
camera={'from':[7.2,2.0,3.6],'look_at':[7.4,1.35,8.4],'fov':68}
spec={'required':'qfep_reactor','shots':[
 dict(camera,tag='sandbox-cut',connected=False,l=.85,p=.7),
 dict(camera,tag='sandbox-connected',connected=True,l=.85,p=.7),
 dict(camera,tag='sandbox-held',connected=False,l=.15,p=-.7),
 dict(camera,tag='sandbox-reconnected',connected=True,l=.15,p=-.7),
 {'tag':'sandbox-controls','from':[7.5,1.5,4.95],'look_at':[7.5,1.05,6.1],'fov':65,'connected':True,'l':.15,'p':-.7},
 {'tag':'sandbox-gallery','from':[10.6,2.0,2.6],'look_at':[6.7,1.25,9.0],'fov':88,'connected':True,'l':.15,'p':-.7}],
 'walks':[{'tag':'entry','from':[7.5,.1,.6],'to':[7.5,.1,3.5],'seconds':3},
 {'tag':'lambda approach','from':[5.5,.1,3.5],'to':[5.5,.1,4.9],'seconds':2},
 {'tag':'phi approach','from':[8.25,.1,3.5],'to':[8.25,.1,4.9],'seconds':2},
 {'tag':'connection switch','from':[7.5,.1,3.5],'to':[7.5,.1,5.5],'seconds':3},
 {'tag':'past the experiment','from':[10.0,.1,4.5],'to':[10.0,.1,12.8],'seconds':6},
 {'tag':'south circulation','from':[10.0,.1,13.5],'to':[7.5,.1,13.5],'seconds':3},
 {'tag':'exit','from':[7.5,.1,13.5],'to':[7.5,.1,15.6],'seconds':3}]}
