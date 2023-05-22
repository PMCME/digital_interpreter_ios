//
//  ViewController.swift
//  PjsipDemo
//
//  Created by Apple on 17/05/23.
//

import UIKit

class PjsipVars: ObservableObject {
    @Published var calling = false
    var dest: String = ""//"sip:1002@fs.dics.se:6443;transport=tcp"
    var call_id: pjsua_call_id = PJSUA_INVALID_ID.rawValue
}


class ViewController: UIViewController {
    
    // Status Label
    @IBOutlet weak var statusLabel: UILabel!
    
    // Sip settings Text Fields
    @IBOutlet weak var sipUsernameTField: UITextField!
    @IBOutlet weak var sipPasswordTField: UITextField!
    
    //Destination Uri to Making outgoing call
    @IBOutlet weak var sipDestinationUriTField: UITextField!
    var status: pj_status_t = 0;
    var objPjSip =  PjsipVars()
    var acc_id :pjsua_acc_id = -1;

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //Create Lib
       // CPPWrapper().createLibWrapper()
        
        //Listen incoming call via function pointer
        //CPPWrapper().incoming_call_wrapper(incoming_call_swift)
     
        //Done button to the keyboard
        sipUsernameTField.addDoneButtonOnKeyboard()
        sipPasswordTField.addDoneButtonOnKeyboard()
        sipDestinationUriTField.addDoneButtonOnKeyboard()
        sipUsernameTField.text = "1001"
        sipPasswordTField.text = "1234"
        sipDestinationUriTField.text =  "1002"
        
        status = pjsua_create();
        if (status != PJ_SUCCESS.rawValue) {
            NSLog("Failed creating pjsua");
        }

        /* Init configs */
        var cfg = pjsua_config();
        cfg.stun_srv_cnt =  2
        cfg.stun_srv.0 = pj_str(strdup("stun:stun.l.google.com:19302"))
        cfg.stun_srv.1 = pj_str(strdup("stun:global.stun.twilio.com:3478"))
        
        var log_cfg = pjsua_logging_config();
        var media_cfg = pjsua_media_config();
        pjsua_config_default(&cfg);
        pjsua_logging_config_default(&log_cfg);
        pjsua_media_config_default(&media_cfg);

        /* Initialize application callbacks */
        
        //cfg.cb.on_call_state =
         cfg.cb.on_call_state = on_call_state;
         cfg.cb.on_call_media_state = on_call_media_state;
         cfg.cb.on_incoming_call = on_incoming_call;
      

        /* Init pjsua */
        status = pjsua_init(&cfg, &log_cfg, &media_cfg);
        
        /* Create transport */
        var transport_id = pjsua_transport_id();
        var tcp_cfg = pjsua_transport_config();
        var tcp_Info = pjsua_transport_info();
        tcp_Info.type_name  = pj_str(strdup("RFC2833"))
        tcp_Info.id = transport_id
        tcp_Info.type = PJSIP_TRANSPORT_TCP
        
        //pjsua_transport_info
        pjsua_transport_config_default(&tcp_cfg);
        tcp_cfg.port = 5060;
        status = pjsua_transport_create(PJSIP_TRANSPORT_TCP,
                                        &tcp_cfg, &transport_id);
        
        status = pjsua_transport_get_info(transport_id,&tcp_Info )
        
    }
    
    
    //Refresh Button
    @IBAction func refreshStatus(_ sender: UIButton) {
//        if (CPPWrapper().registerStateInfoWrapper()){
//            statusLabel.text = "Sip Status: REGISTERED"
//        }else {
//            statusLabel.text = "Sip Status: NOT REGISTERED"
//        }
    }
    
    
    //Login Button
    @IBAction func loginClick(_ sender: UIButton) {
    
        if self.sipUsernameTField.text == "" || self.sipPasswordTField.text == "" {
            let alert = UIAlertController(title: "SIP SETTINGS ERROR", message: "Please fill the form / Logout", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                switch action.style{
                    case .default:
                    print("default")
                    
                    case .cancel:
                    print("cancel")
                    
                    case .destructive:
                    print("destructive")
                    
                @unknown default:
                    fatalError()
                }
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        let uName = self.sipUsernameTField.text ?? ""
        let pwd = self.sipPasswordTField.text ?? ""
        let id = strdup("sip:\(uName)@fs.dics.se:6443");
        let username = strdup(uName);
        let passwd = strdup(pwd);
        let realm = strdup("*");
        let registrar = strdup("sip:fs.dics.se");
        let proxy = strdup("sip:fs.dics.se;transport=tcp");

        var opt = pjsua_call_setting();
        opt.aud_cnt = 1;
        opt.vid_cnt = 1;
        
        pjsua_call_setting_default(&opt);
        
        
        var acc_cfg = pjsua_acc_config();
        pjsua_acc_config_default(&acc_cfg);
        acc_cfg.reg_timeout = 600;
        acc_cfg.sip_stun_use = PJSUA_STUN_RETRY_ON_FAILURE;
        acc_cfg.media_stun_use = PJSUA_STUN_RETRY_ON_FAILURE;
        acc_cfg.id = pj_str(id);
        acc_cfg.cred_count = 1;
        acc_cfg.cred_info.0.username = pj_str(username);
        acc_cfg.cred_info.0.realm = pj_str(realm);
        acc_cfg.cred_info.0.data = pj_str(passwd);
        acc_cfg.reg_uri = pj_str(registrar);
        
        acc_cfg.proxy_cnt = 1;
        acc_cfg.proxy.0 = pj_str(proxy);
        acc_cfg.vid_out_auto_transmit = pj_bool_t(PJ_TRUE.rawValue);
        acc_cfg.vid_in_auto_show = pj_bool_t(PJ_TRUE.rawValue);
        acc_cfg.vid_cap_dev = PJMEDIA_VID_DEFAULT_CAPTURE_DEV.rawValue;
        acc_cfg.vid_rend_dev = PJMEDIA_VID_DEFAULT_RENDER_DEV.rawValue;
        acc_cfg.vid_wnd_flags = PJMEDIA_VID_DEV_WND_RESIZABLE.rawValue;
        acc_cfg.reg_retry_interval = 300;
        acc_cfg.reg_first_retry_interval = 30;
        
        /* Add account */
        let accountAddStaus = pjsua_acc_add(&acc_cfg, pj_bool_t(PJ_TRUE.rawValue), &acc_id);
        if accountAddStaus != PJ_SUCCESS.rawValue {
            statusLabel.text = "Sip Status: NOT REGISTERED"
        } else {
            statusLabel.text = "Sip Status: REGISTERED"
        }
        
        /* Free strings */
        free(id); free(username); free(passwd); free(realm);
        free(registrar); free(proxy);
        
        /* Start pjsua */
        status = pjsua_start();
        
   

    }
    
    //Logout Button
    @IBAction func logoutClick(_ sender: UIButton) {
        
//        /**
//        Only unregister from an account.
//         */
//        //Unregister
//        CPPWrapper().unregisterAccountWrapper()
//
//        //Wait until register/unregister
//        sleep(2)
//        if (CPPWrapper().registerStateInfoWrapper()){
//            statusLabel.text = "Sip Status: REGISTERED"
//        } else {
//            statusLabel.text = "Sip Status: NOT REGISTERED"
//        }
    }

    
    
    //Call Button
    @IBAction func callClick(_ sender: UIButton) {
        let destination =  self.sipDestinationUriTField.text ?? ""
        objPjSip.dest  = "sip:\(destination)@fs.dics.se"//:6443;transport=tcp"
        let user_data =                     UnsafeMutableRawPointer(Unmanaged.passUnretained(objPjSip).toOpaque())
        
        call_func(user_data: user_data, account_id: acc_id)
     //  pjsua_schedule_timer2_dbg(call_func, user_data, 0, "swift", 0)
    }
    
    
}


extension UITextField{
    @IBInspectable var doneAccessory: Bool{
        get{
            return self.doneAccessory
        }
        set (hasDone) {
            if hasDone{
                addDoneButtonOnKeyboard()
            }
        }
    }

    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))

        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()

        self.inputAccessoryView = doneToolbar
    }

    @objc func doneButtonAction()
    {
        self.resignFirstResponder()
    }
    
    
}

//MARK: Private Function
private func on_call_state(call_id: pjsua_call_id, e: UnsafeMutablePointer<pjsip_event>?) {
    
    var ci = pjsua_call_info();
    pjsua_call_get_info(call_id, &ci);
    print("on call state: \(ci.state.rawValue)")
    if (ci.state == PJSIP_INV_STATE_DISCONNECTED) {
        /* UIView update must be done in the main thread */
        DispatchQueue.main.sync {
            print("Coming in On Call State")
            
            //AppDelegate.Shared.vinfo.vid_win = nil;
        }
    }
}

private func tupleToArray<Tuple, Value>(tuple: Tuple) -> [Value] {
    let tupleMirror = Mirror(reflecting: tuple)
    return tupleMirror.children.compactMap { (child: Mirror.Child) -> Value? in
        return child.value as? Value
    }
}

private func on_call_media_state(call_id: pjsua_call_id) {
    var ci = pjsua_call_info();
    pjsua_call_get_info(call_id, &ci);

    for mi in 0...ci.media_cnt {
        let media: [pjsua_call_media_info] = tupleToArray(tuple: ci.media);

        if (media[Int(mi)].status == PJSUA_CALL_MEDIA_ACTIVE ||
            media[Int(mi)].status == PJSUA_CALL_MEDIA_REMOTE_HOLD)
        {
            switch (media[Int(mi)].type) {
            case PJMEDIA_TYPE_AUDIO:
                var call_conf_slot: pjsua_conf_port_id;

                call_conf_slot = media[Int(mi)].stream.aud.conf_slot;
                pjsua_conf_connect(call_conf_slot, 0);
                pjsua_conf_connect(0, call_conf_slot);
                break;
        
            case PJMEDIA_TYPE_VIDEO:
                let wid = media[Int(mi)].stream.vid.win_in;
                var wi = pjsua_vid_win_info();
                    
                if (pjsua_vid_win_get_info(wid, &wi) == PJ_SUCCESS.rawValue) {
                    let vid_win:UIView =
                        Unmanaged<UIView>.fromOpaque(wi.hwnd.info.ios.window).takeUnretainedValue();

                    /* UIView update must be done in the main thread */
                    DispatchQueue.main.sync {
                        print("Coming in on_call_media_state")
                         displayVideoView(vid_win)
                       // AppDelegate.Shared.vinfo.vid_win = vid_win;
                    }
                }
                break;
            
            default:
                break;
            }
        }
    }
}

/*(pjsua_acc_id acc_id, pjsua_call_id call_id,
 pjsip_rx_data *rdata)*/
private func on_incoming_call(acc_id: pjsua_acc_id, call_id: pjsua_call_id, rdata: UnsafeMutablePointer<pjsip_rx_data>?) {
    print("Incoming call is received-- \(acc_id)")
    var ci: pjsua_call_info = pjsua_call_info()
    var opt: pjsua_call_setting = pjsua_call_setting()
    pjsua_call_setting_default(&opt)
    var pParam: pjsua_vid_preview_param = pjsua_vid_preview_param()
    pjsua_vid_preview_param_default(&pParam)
    
    pParam.show = pj_bool_t(PJ_TRUE.rawValue);
    
    opt.aud_cnt = 1 // number of simultaneous audio calls
    opt.vid_cnt = 1 // number of simultaneous video calls
    
//    free(accId)
     //free(rdata)
   
    
    pjsua_call_get_info(call_id, &ci)
    
  //  PJ_LOG(3, (THIS_FILE, "Incoming call from %.*s!!",
 //               Int32(ci.remote_info.slen),
 //               ci.remote_info.ptr))
    pjsua_call_answer2(call_id, &opt, 200, nil, nil)
}




private func call_func(user_data: UnsafeMutableRawPointer? , account_id : pjsua_acc_id) {
    print("Going in call function")
    let pjsip_vars = Unmanaged<PjsipVars>.fromOpaque(user_data!).takeUnretainedValue()
    if (!pjsip_vars.calling) {
        var status: pj_status_t;
        var opt = pjsua_call_setting();

        pjsua_call_setting_default(&opt);
        opt.aud_cnt = 1;
        opt.vid_cnt = 1;
        
         print("Destinlation URL:\(pjsip_vars.dest)")
        let dest_str = strdup(pjsip_vars.dest);
        var dest:pj_str_t = pj_str(dest_str);
        status = pjsua_call_make_call(account_id, &dest, &opt, nil, nil, &pjsip_vars.call_id);//&pjsip_vars.call_id
        if (status != PJ_SUCCESS.rawValue)
        {
            print("error making in call")
           //pjsua_perror(THIS_FILE, "Error making call", status);
        }
//        DispatchQueue.main.sync {
//            pjsip_vars.calling = (status == PJ_SUCCESS.rawValue);
//        }
        free(dest_str);
    } else {
        if (pjsip_vars.call_id != PJSUA_INVALID_ID.rawValue) {
            DispatchQueue.main.sync {
                pjsip_vars.calling = false;
            }
            pjsua_call_hangup(pjsip_vars.call_id, 200, nil, nil);
            pjsip_vars.call_id = PJSUA_INVALID_ID.rawValue;
        }
    }

}


/*
 **> Please check this registration  scenarios**

     pj_status_t sip_startup(app_config_t *app_config)
     {
       pj_status_t status;
       long val;
       char tmp[80];
       pjsua_transport_id transport_id = -1;
       const char *srv;
           const char *ip_addr;

       NSArray * array;
       NSString *dns;

       SiphonApplication *app = (SiphonApplication *)[SiphonApplication sharedApplication];

       /* Create pjsua first! */
       status = pjsua_create();
       if (status != PJ_SUCCESS)
         return status;

       /* Create pool for application */
       app_config->pool = pjsua_pool_create("pjsua", 1000, 1000);

       /* Initialize default config */
       pjsua_config_default(&(app_config->cfg));
       pj_ansi_snprintf(tmp, 80, "Siphon PjSip v%s/%s", pj_get_version(), PJ_OS_NAME);
       pj_strdup2_with_null(app_config->pool, &(app_config->cfg.user_agent), tmp);

       pjsua_logging_config_default(&(app_config->log_cfg));

       val = [[NSUserDefaults standardUserDefaults] integerForKey:
              @"logLevel"];
     #ifdef RELEASE_VERSION
       app_config->log_cfg.msg_logging = PJ_FALSE;
       app_config->log_cfg.console_level = 0;
       app_config->log_cfg.level = 0;
     #else
       app_config->log_cfg.msg_logging = (val!=0 ? PJ_TRUE : PJ_FALSE);
       app_config->log_cfg.console_level = val;
       app_config->log_cfg.level = val;
       if (val != 0)
       {
     #if defined(CYDIA) && (CYDIA == 1)
         NSArray *filePaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
         NSString *path = [NSString stringWithFormat:@"%@/Siphon", [filePaths objectAtIndex:0]];
     #else
         NSArray *filePaths =    NSSearchPathForDirectoriesInDomains (NSDocumentDirectory,
                                                                    NSUserDomainMask,
                                                                    YES);
             NSString *path = [filePaths objectAtIndex: 0];
     #endif
         //NSString *path = NSTemporaryDirectory();
         path = [path stringByAppendingString: @"/log.txt"];

         app_config->log_cfg.log_filename = pj_strdup3(app_config->pool,
                                                       [path UTF8String]);
       }
     #endif

       pjsua_media_config_default(&(app_config->media_cfg));

       // TODO select clock rate with enabled codec (8000 if nb codec only, or 16000 and more if wb codec)
       //app_config->media_cfg.clock_rate = 8000;
       //app_config->media_cfg.snd_clock_rate = 8000;
       app_config->media_cfg.clock_rate = 16000;
       app_config->media_cfg.snd_clock_rate = 16000;
       //app_config->media_cfg.ec_options = 0;//0=default,1=speex, 2=suppressor

       if (![[NSUserDefaults standardUserDefaults] boolForKey:@"enableEC"])
         app_config->media_cfg.ec_tail_len = 0;

       // Enable/Disable VAD/silence detector
       app_config->media_cfg.no_vad = [[NSUserDefaults standardUserDefaults]
                                       boolForKey:@"disableVad"];

       app_config->media_cfg.snd_auto_close_time = 0;
       //app_config->media_cfg.quality = 2;
       //app_config->media_cfg.channel_count = 2;

       app_config->media_cfg.enable_ice = [[NSUserDefaults standardUserDefaults]
                                           boolForKey:@"enableICE"];

       pjsua_transport_config_default(&(app_config->udp_cfg));
       val = [[NSUserDefaults standardUserDefaults] integerForKey: @"localPort"];
       if (val < 0 || val > 65535)
       {
         PJ_LOG(1,(THIS_FILE,
           "Error: local-port argument value (expecting 0-65535"));
         [app displayParameterError:
          @"Invalid value for Local Port (expecting 1-65535)."];

         status = PJ_EINVAL;
         goto error;
       }
       app_config->udp_cfg.port = val;

       pjsua_transport_config_default(&(app_config->rtp_cfg));
       app_config->rtp_cfg.port = [[NSUserDefaults standardUserDefaults]
         integerForKey: @"rtpPort"];
       if (app_config->rtp_cfg.port == 0)
       {
         enum { START_PORT=4000 };
         unsigned range;

         range = (65535-START_PORT-PJSUA_MAX_CALLS*4);
         app_config->rtp_cfg.port = START_PORT +
                 ((pj_rand() % range) & 0xFFFE);
       }

       if (app_config->rtp_cfg.port < 1 || app_config->rtp_cfg.port > 65535)
       {
         PJ_LOG(1,(THIS_FILE,
             "Error: rtp-port argument value (expecting 1-65535)"));
         [app displayParameterError:
          @"Invalid value for RTP port (expecting 1-65535)."];
         status = PJ_EINVAL;
         goto error;
       }

     #if 1 // TEST pour le vpn
       ip_addr = [[[NSUserDefaults standardUserDefaults] stringForKey:
                   @"boundAddr"] UTF8String];
       if (ip_addr && strlen(ip_addr))
       {
         pj_strdup2_with_null(app_config->pool,
                              &(app_config->udp_cfg.bound_addr),
                              ip_addr);
         pj_strdup2_with_null(app_config->pool,
                              &(app_config->rtp_cfg.bound_addr),
                              ip_addr);
       }

       ip_addr = [[[NSUserDefaults standardUserDefaults] stringForKey:
                   @"publicAddr"] UTF8String];
       if (ip_addr && strlen(ip_addr))
       {
         pj_strdup2_with_null(app_config->pool,
                              &(app_config->udp_cfg.public_addr),
                              ip_addr);
         pj_strdup2_with_null(app_config->pool,
                              &(app_config->rtp_cfg.public_addr),
                              ip_addr);
       }
     #endif

       /* Initialize application callbacks */
       app_config->cfg.cb.on_call_state = &on_call_state;
       app_config->cfg.cb.on_call_media_state = &on_call_media_state;
       app_config->cfg.cb.on_incoming_call = &on_incoming_call;
       app_config->cfg.cb.on_reg_state = &on_reg_state;
     #if defined(MWI) && MWI==1
       app_config->cfg.cb.on_mwi_info = &on_mwi_info;
       app_config->cfg.enable_unsolicited_mwi = PJ_TRUE;
     #endif

       srv = [[[NSUserDefaults standardUserDefaults] stringForKey:
                   @"stunServer"] UTF8String];
       if (srv && strlen(srv))
       {
         if (app_config->cfg.stun_srv_cnt==PJ_ARRAY_SIZE(app_config->cfg.stun_srv))
         {
           PJ_LOG(1,(THIS_FILE, "Error: too many STUN servers"));
           return PJ_ETOOMANY;
         }
         pj_strdup2_with_null(app_config->pool,
                              &(app_config->cfg.stun_srv[app_config->cfg.stun_srv_cnt++]),
                              srv);
       }

      // app_config->cfg.outbound_proxy[0] = pj_str(outbound_proxy);
      // app_config->cfg.outbound_proxy_cnt = 1;

       dns = [[NSUserDefaults standardUserDefaults] stringForKey: @"dnsServer"];
       array = [dns componentsSeparatedByString:@","];
       NSEnumerator *enumerator = [array objectEnumerator];
       NSString *anObject;
       while (anObject = [enumerator nextObject])
       {
         NSMutableString *mutableStr = [anObject mutableCopy];
         CFStringTrimWhitespace((CFMutableStringRef)mutableStr);
         srv = [mutableStr UTF8String];
         if (srv && strlen(srv))
         {
           if (app_config->cfg.nameserver_count==PJ_ARRAY_SIZE(app_config->cfg.nameserver))
           {
             PJ_LOG(1,(THIS_FILE, "Error: too many DNS servers"));
             [mutableStr release];
             break;
           }
           pj_strdup2_with_null(app_config->pool,
                                &(app_config->cfg.nameserver[app_config->cfg.nameserver_count++]),
                                srv);
         }
           [mutableStr release];
       }
       //[enumerator release];
       //[array release];

       /* Initialize pjsua */
       status = pjsua_init(&app_config->cfg, &app_config->log_cfg,
         &app_config->media_cfg);
       if (status != PJ_SUCCESS)
         goto error;

       /* Initialize Ring and Ringback */
       sip_ring_init(app_config);

       /* Add UDP transport. */
       status = pjsua_transport_create(PJSIP_TRANSPORT_UDP,
               &app_config->udp_cfg, &transport_id);
       if (status != PJ_SUCCESS)
         goto error;

       /* Add RTP transports */
      // status = pjsua_media_transports_create(&app_config->rtp_cfg);
      // if (status != PJ_SUCCESS)
       //  goto error;

     #if LOCAL_ACCOUNT
       {
         if (status == PJ_SUCCESS  && transport_id != -1)
         {
           /* Add local account */
           pjsua_acc_add_local(transport_id, PJ_TRUE, &aid);
         }
       }
     #endif

       /* */
       sip_manage_codec();

       /* Initialization is done, now start pjsua */
       status = pjsua_start();
       if (status != PJ_SUCCESS)
         goto error;

       return status;
     error:
       sip_cleanup(app_config);
       return status;
     }



 /* */
 pj_status_t sip_cleanup(app_config_t *app_config)
 {
   pj_status_t status;

   /* Cleanup Ring and Ringback */
   sip_ring_deinit(app_config);

   if (app_config->pool)
   {
     pj_pool_release(app_config->pool);
     app_config->pool = NULL;
   }

   /* Destroy pjsua */
   status = pjsua_destroy();

   pj_bzero(app_config, sizeof(app_config_t));

   return status;

 }

 /* */
 pj_status_t sip_connect(pj_pool_t *pool, pjsua_acc_id *acc_id)
 {
   pj_status_t status;
   pjsua_acc_config acc_cfg;
   const char *uname;
   const char *authname;
   const char *contactname;
   const char *passwd;
   const char *server;

   SiphonApplication *app = (SiphonApplication *)[SiphonApplication sharedApplication];

   // TODO Verify if wifi is connected, if not verify if user wants edge connection

   uname  = [[[NSUserDefaults standardUserDefaults] stringForKey:
              @"username"] UTF8String];
   authname  = [[[NSUserDefaults standardUserDefaults] stringForKey:
                 @"authname"] UTF8String];
   contactname  = [[[NSUserDefaults standardUserDefaults] stringForKey:
                 @"contact"] UTF8String];
   passwd = [[[NSUserDefaults standardUserDefaults] stringForKey:
              @"password"] UTF8String];
   server = [[[NSUserDefaults standardUserDefaults] stringForKey:
              @"server"] UTF8String];

   pjsua_acc_config_default(&acc_cfg);

   // ID
   acc_cfg.id.ptr = (char*) pj_pool_alloc(/*app_config.*/pool, PJSIP_MAX_URL_SIZE);
   if (contactname && strlen(contactname))
     acc_cfg.id.slen = pj_ansi_snprintf(acc_cfg.id.ptr, PJSIP_MAX_URL_SIZE,
                                        "\"%s\"<sip:%s@%s>", contactname, uname, server);
   else
     acc_cfg.id.slen = pj_ansi_snprintf(acc_cfg.id.ptr, PJSIP_MAX_URL_SIZE,
                                        "sip:%s@%s", uname, server);
   if ((status = pjsua_verify_sip_url(acc_cfg.id.ptr)) != 0)
   {
     PJ_LOG(1,(THIS_FILE, "Error: invalid SIP URL '%s' in local id argument",
       acc_cfg.id));
     [app displayParameterError: @"Invalid value for username or server."];
     return status;
   }

   // Registrar
   acc_cfg.reg_uri.ptr = (char*) pj_pool_alloc(/*app_config.*/pool,
     PJSIP_MAX_URL_SIZE);
   acc_cfg.reg_uri.slen = pj_ansi_snprintf(acc_cfg.reg_uri.ptr,
     PJSIP_MAX_URL_SIZE, "sip:%s", server);
   if ((status = pjsua_verify_sip_url(acc_cfg.reg_uri.ptr)) != 0)
   {
     PJ_LOG(1,(THIS_FILE,  "Error: invalid SIP URL '%s' in registrar argument",
       acc_cfg.reg_uri));
     [app displayParameterError: @"Invalid value for server parameter."];
     return status;
   }

   //acc_cfg.id = pj_str(id);
   //acc_cfg.reg_uri = pj_str(registrar);
   acc_cfg.cred_count = 1;
   acc_cfg.cred_info[0].scheme = pj_str("Digest");
   acc_cfg.cred_info[0].realm = pj_str("*");//pj_str(realm);
   if (authname && strlen(authname))
     acc_cfg.cred_info[0].username = pj_str((char *)authname);
   else
     acc_cfg.cred_info[0].username = pj_str((char *)uname);
   if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enableMJ"])
     acc_cfg.cred_info[0].data_type = PJSIP_CRED_DATA_DIGEST;
   else
     acc_cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
   acc_cfg.cred_info[0].data = pj_str((char *)passwd);

   acc_cfg.publish_enabled = PJ_TRUE;
 #if defined(MWI) && MWI==1
   acc_cfg.mwi_enabled = PJ_TRUE;
 #endif

   acc_cfg.allow_contact_rewrite = [[NSUserDefaults standardUserDefaults]
                                    boolForKey:@"enableNat"];

   // FIXME: gestion du message 423 dans pjsip
   acc_cfg.reg_timeout = [[NSUserDefaults standardUserDefaults] integerForKey:
     @"regTimeout"];

   if (acc_cfg.reg_timeout < 1 || acc_cfg.reg_timeout > 3600)
   {
     PJ_LOG(1,(THIS_FILE,
       "Error: invalid value for timeout (expecting 1-3600)"));
     [app displayParameterError:
           @"Invalid value for timeout (expecting 1-3600)."];
     return PJ_EINVAL;
   }

   // Keep alive interval
   acc_cfg.ka_interval = [[NSUserDefaults standardUserDefaults] integerForKey:
                     @"kaInterval"];

   // proxies server
   NSString *proxies = [[NSUserDefaults standardUserDefaults] stringForKey: @"proxyServer"];
   NSArray *array = [proxies componentsSeparatedByString:@","];
   NSEnumerator *enumerator = [array objectEnumerator];
   NSString *anObject;
   while (anObject = [enumerator nextObject])
   {
     NSMutableString *mutableStr = [anObject mutableCopy];
     CFStringTrimWhitespace((CFMutableStringRef)mutableStr);
     const char *proxy = [mutableStr UTF8String];
     if (proxy && strlen(proxy))
     {
       if (acc_cfg.proxy_cnt==PJ_ARRAY_SIZE(acc_cfg.proxy))
       {
         PJ_LOG(1,(THIS_FILE, "Error: too many proxy servers"));
         [mutableStr release];
         break;
       }
       pj_str_t pj_proxy;
       pj_proxy.slen = strlen(proxy) + 8;
       pj_proxy.ptr = (char*) pj_pool_alloc(pool, pj_proxy.slen);
       pj_proxy.slen = pj_ansi_snprintf(pj_proxy.ptr, pj_proxy.slen, "sip:%s;lr", proxy);
       if ((status = pjsua_verify_sip_url(pj_proxy.ptr)) != 0)
       {
         PJ_LOG(1,(THIS_FILE,  "Error: invalid SIP URL '%*.s' in proxy argument (%d)",
                   pj_proxy.slen, pj_proxy.ptr, status));
         [mutableStr release];
         [app displayParameterError: @"Invalid value for proxy parameter."];
         continue;
       }
       acc_cfg.proxy[acc_cfg.proxy_cnt++] = pj_proxy;
     }
     [mutableStr release];
   }

 #if LOCAL_ACCOUNT
  *acc_id = aid;
 #else
   status = pjsua_acc_add(&acc_cfg, PJ_TRUE, acc_id);
   if (status != PJ_SUCCESS)
   {
     pjsua_perror(THIS_FILE, "Error adding new account", status);
     [app displayParameterError: @"Error adding new account."];
   }
 #endif
   return status;
 }

 /* */
 pj_status_t sip_disconnect(pjsua_acc_id *acc_id)
 {
   pj_status_t status = PJ_SUCCESS;

   if (pjsua_acc_is_valid(*acc_id))
   {
     status = pjsua_acc_del(*acc_id);
     if (status == PJ_SUCCESS)
       *acc_id = PJSUA_INVALID_ID;
   }

   return status;
 }

 /* */
 pj_status_t sip_dial_with_uri(pjsua_acc_id acc_id, const char *uri,
                      pjsua_call_id *call_id)
 {
   // FIXME: récupérer le domain à partir du compte (acc_id);
   // TODO be careful app already mustn't be in communication!
   // TODO if not SIP connected, use GSM ? NSURL with 'tel' protocol
   pj_status_t status = PJ_SUCCESS;
   pj_str_t pj_uri;

 //  pjsua_msg_data msg_data;
 //  pjsip_generic_string_hdr subject;
 //  pj_str_t hvalue, hname;

   PJ_LOG(5,(THIS_FILE,  "Calling URI \"%s\".", uri));

   status = pjsua_verify_sip_url(uri);
   if (status != PJ_SUCCESS)
   {
     PJ_LOG(1,(THIS_FILE,  "Invalid URL \"%s\".", uri));
     pjsua_perror(THIS_FILE, "Invalid URL", status);
     return status;
   }

   pj_uri = pj_str((char *)uri);
  //status = pjsua_set_null_snd_dev();

   status =  pjsua_snd_is_active();

 //  hname = pj_str("Subject");
 //  hvalue = pj_str("phone call");
 //
 //  pjsua_msg_data_init(&msg_data);
 //  pjsip_generic_string_hdr_init2(&subject, &hname, &hvalue);
 //  pj_list_push_back(&msg_data.hdr_list, &subject);
 //
 //  status = pjsua_call_make_call(acc_id, &pj_uri, 0, NULL, &msg_data, call_id);
   status = pjsua_call_make_call(acc_id, &pj_uri, 0, NULL, NULL, call_id);
   if (status != PJ_SUCCESS)
   {
     pjsua_perror(THIS_FILE, "Error making call", status);
   }

   return status;
 }

 pj_status_t sip_dial(pjsua_acc_id acc_id, const char *number,
   pjsua_call_id *call_id)
 {
   // FIXME: récupérer le domain à partir du compte (acc_id);f
   // TODO be careful app already mustn't be in communication!
   // TODO if not SIP connected, use GSM ? NSURL with 'tel' protocol
   char uri[256];
   const char *sip_domain;

   sip_domain = [[[NSUserDefaults standardUserDefaults] stringForKey:
     @"server"] UTF8String];

   pj_ansi_snprintf(uri, 256, "sip:%s@%s", number, sip_domain);
   return sip_dial_with_uri(acc_id, uri, call_id);
 }

 /* */
 pj_status_t sip_answer(pjsua_call_id *call_id)
 {
   pj_status_t status;
     status = pjsua_set_null_snd_dev();

   status = pjsua_call_answer(*call_id, 200, NULL, NULL);
   if (status != PJ_SUCCESS)
   {
     *call_id = PJSUA_INVALID_ID;
   }

   return status;
 }

 /* */
 pj_status_t sip_hangup(pjsua_call_id *call_id)
 {
   pj_status_t status = PJ_SUCCESS;

   //pjsua_call_hangup_all();
   /* TODO Hangup current calls */
   if (*call_id != PJSUA_INVALID_ID)
     status = pjsua_call_hangup(*call_id, 0, NULL, NULL);
   *call_id = PJSUA_INVALID_ID;

   return status;
 }

 #if SETTINGS
 /* */
 pj_status_t sip_add_account(NSDictionary *account, pjsua_acc_id *acc_id)
 {
   pj_status_t status;
   pjsua_acc_config acc_cfg;
   const char *uname;
   const char *passwd;
   const char *server;
   const char *proxy;

   SiphonApplication *app = (SiphonApplication *)[SiphonApplication sharedApplication];
   app_config_t *app_config = [app pjsipConfig];

   // TODO Verify if wifi is connected, if not verify if user wants edge connection

   uname  = [[account objectForKey: @"username"] UTF8String];
   passwd = [[account objectForKey: @"password"] UTF8String];
   server = [[account objectForKey: @"server"] UTF8String];
   proxy  = [[account objectForKey: @"proxyServer"] UTF8String];

   pjsua_acc_config_default(&acc_cfg);

   // ID
   acc_cfg.id.ptr = (char*) pj_pool_alloc(app_config->pool, PJSIP_MAX_URL_SIZE);
   acc_cfg.id.slen = pj_ansi_snprintf(acc_cfg.id.ptr, PJSIP_MAX_URL_SIZE,
                                      "sip:%s@%s", uname, server);
   // FIXME : verify in settings view
   if ((status = pjsua_verify_sip_url(acc_cfg.id.ptr)) != 0)
   {
     PJ_LOG(1,(THIS_FILE, "Error: invalid SIP URL '%s' in local id argument",
               acc_cfg.id));
     [app displayParameterError: @"Invalid value for username or server."];
     return status;
   }

   // Registrar
   acc_cfg.reg_uri.ptr = (char*) pj_pool_alloc(app_config->pool,
                                               PJSIP_MAX_URL_SIZE);
   acc_cfg.reg_uri.slen = pj_ansi_snprintf(acc_cfg.reg_uri.ptr,
                                           PJSIP_MAX_URL_SIZE, "sip:%s", server);
   // FIXME : verify in settings view
   if ((status = pjsua_verify_sip_url(acc_cfg.reg_uri.ptr)) != 0)
   {
     PJ_LOG(1,(THIS_FILE,  "Error: invalid SIP URL '%s' in registrar argument",
               acc_cfg.reg_uri));
     [app displayParameterError: @"Invalid value for server parameter."];
     return status;
   }

   //acc_cfg.id = pj_str(id);
   //acc_cfg.reg_uri = pj_str(registrar);
   acc_cfg.cred_count = 1;
   acc_cfg.cred_info[0].scheme = pj_str("Digest");
   acc_cfg.cred_info[0].realm = pj_str("*");//pj_str(realm);
   acc_cfg.cred_info[0].username = pj_str((char *)uname);
   acc_cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
   acc_cfg.cred_info[0].data = pj_str((char *)passwd);

   acc_cfg.publish_enabled = PJ_TRUE;

   acc_cfg.allow_contact_rewrite = [[account objectForKey:@"enableNat"] boolValue];

   // FIXME: gestion du message 423 dans pjsip
   acc_cfg.reg_timeout = [[account objectForKey: @"regTimeout"] intValue];
   // FIXME : verify in settings view
   if (acc_cfg.reg_timeout < 1 || acc_cfg.reg_timeout > 3600)
   {
     PJ_LOG(1,(THIS_FILE,
               "Error: invalid value for timeout (expecting 1-3600)"));
     [app displayParameterError:
      @"Invalid value for timeout (expecting 1-3600)."];
     return PJ_EINVAL;
   }

   pj_str_t pj_proxy = pj_str((char *)proxy);
   if (pj_strlen(&pj_proxy) > 0)
   {
     acc_cfg.proxy[0].ptr = (char*) pj_pool_alloc(app_config->pool,
                                                  PJSIP_MAX_URL_SIZE);
     acc_cfg.proxy[0].slen = pj_ansi_snprintf(acc_cfg.proxy[0].ptr,
                                              PJSIP_MAX_URL_SIZE, "sip:%s;lr", proxy);
     // FIXME verify in settings view
     if ((status = pjsua_verify_sip_url(acc_cfg.proxy[0].ptr)) != 0)
     {
       PJ_LOG(1,(THIS_FILE,  "Error: invalid SIP URL '%s' in proxy argument",
                 acc_cfg.reg_uri));
       [app displayParameterError: @"Invalid value for proxy parameter."];
       return status;
     }
     acc_cfg.proxy_cnt = 1;
   }

   status = pjsua_acc_add(&acc_cfg, PJ_TRUE, acc_id);
   if (status != PJ_SUCCESS)
   {
     pjsua_perror(THIS_FILE, "Error adding new account", status);
     [app displayParameterError: @"Error adding new account."];
   }

   return status;
 }
 #endif
 */
