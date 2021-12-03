import UIKit
import PhotosUI     //引入iOS15之後使用的相簿UI框架
//import CoreLocation //引入核心定位框架(可能已經預先引入)
import MapKit       //引入地圖框架

class DetailViewController: UIViewController,UIPickerViewDelegate,UIPickerViewDataSource,UIImagePickerControllerDelegate,UINavigationControllerDelegate,PHPickerViewControllerDelegate,URLSessionTaskDelegate
{
    @IBOutlet weak var lblNo: UILabel!
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtGender: UITextField!
    @IBOutlet weak var imgPicture: UIImageView!
    @IBOutlet weak var txtPhone: UITextField!
    @IBOutlet weak var txtMyclass: UITextField!
    @IBOutlet weak var txtAddress: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    
    //---------------------MySQL增加-----------------------
    //記錄主要提供web service的網址
//    let webDomain = "http://192.168.1.113/"
    let webDomain = "http://studio-pj.com/class_exercise/"
    //紀錄目前處理中的網路服務
    var strURL = ""     //ex.select_data.php
    //紀錄目前處理中的網路物件
    var url:URL!
    //取得預設的網路串流物件
    var session:URLSession!
    //宣告網路資料傳輸任務（可同時適用於上傳和下載）
    var dataTask:URLSessionDataTask!
    //判斷大頭照是否已經上傳到伺服器（預設大頭照已上傳）
    var isFileUploaded = true
    //----------------------------------------------------
    
    //接收上一頁的執行實體
    weak var myTableVC:MyTableViewController!
    //紀錄目前被點選的資料行
    var currentRow = 0
    //紀錄目前處理中的學生資料
    var currentData = Student()
    //提供性別及班別滾輪的資料輸入介面
    var pkvGender:UIPickerView!
    var pkvClass:UIPickerView!
    //提供性別及班別滾輪的選擇資料
    let arrGender = ["女","男"]
    let arrClass = ["手機程式設計","網頁程式設計","智能裝置開發"]
    //紀錄目前輸入元件的Y軸底緣位置
    var currentObjectBottomYPoistion:CGFloat = 0
    
    //MARK: - 自定函式
    //由通知中心在鍵盤彈出時呼叫的函式
    @objc func keyboardWillShow(_ notification:Notification)
    {
        print("鍵盤彈出：\(notification.userInfo!)")
    
        if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        {
            print("鍵盤高度：\(keyboardHeight.height)")
            //計算扣除鍵盤遮擋範圍之後的剩餘"可視高度"
            let visiableHeight = self.view.bounds.height - keyboardHeight.height
            //當鍵盤被遮住時，輸入元件的Y軸底緣位置會大於可視高度
            if currentObjectBottomYPoistion > visiableHeight
            {
                //向上位移『Y軸底緣位置』與『可視高度』的差值
                self.view.frame.origin.y -= currentObjectBottomYPoistion - visiableHeight
            }
        }
    }
    
    //由通知中心在鍵盤收合時呼叫的函式
    @objc func keyboardWillHide()
    {
        print("鍵盤收合")
        //將上移的畫面歸回原點
        self.view.frame.origin.y = 0
    }
    
    //MARK: - Target Action
    //由虛擬鍵盤的return鍵觸發的事件
    @IBAction func didEndOnExit(_ sender: UITextField)
    {
        //不需實作即可收起鍵盤
    }
    
    //文字輸入框開始編輯時
    @IBAction func editingDidBegin(_ sender: UITextField)
    {
        switch sender.tag
        {
            //電話欄位編輯時
            case 4:
                //使用數字鍵盤
                sender.keyboardType = .numberPad
            //Email欄位編輯時
            case 7:
                //使用Email鍵盤
                sender.keyboardType = .emailAddress
            default:    //其他種類的欄位
                //使用預設鍵盤
                sender.keyboardType = .default
        }
        //計算目前輸入元件的Y軸底緣位置
        currentObjectBottomYPoistion = sender.frame.origin.y + sender.frame.size.height
    }
    //相機按鈕
    @IBAction func buttonCamera(_ sender: UIButton)
    {
        guard UIImagePickerController.isSourceTypeAvailable(.camera)
        else
        {
            print("無法使用相機")
            return  //直接離開
        }
        //如果可以使用相機，即產生影像挑選控制器
        let imagePicker = UIImagePickerController()
        //將影像挑選控制器呈現為相機
        imagePicker.sourceType = .camera
        //將imagePicker相關的代理方法實作在此類別
        imagePicker.delegate = self
        //開啟拍照介面
//        show(imagePicker, sender: nil)
        present(imagePicker, animated: true, completion: nil)
    }
    //相簿按鈕
    @IBAction func buttonPhotoAlbum(_ sender: UIButton)
    {
        //<方法一>iOS14以前的相簿取用方法
//        //如果可以使用相機，即產生影像挑選控制器
//        let imagePicker = UIImagePickerController()
//        //將影像挑選控制器呈現為相簿
//        imagePicker.sourceType = .photoLibrary
//        //將imagePicker相關的代理方法實作在此類別
//        imagePicker.delegate = self
//        //開啟拍照介面
////        show(imagePicker, sender: nil)
//        present(imagePicker, animated: true, completion: nil)
        //<方法二>iOS15之後的相簿取用方法
        //設定挑選相簿時使用的組態
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = PHPickerFilter.images
        configuration.preferredAssetRepresentationMode = .current
        configuration.selection = .ordered
        //設定可以多選（0不限張數，1為預設）
//        configuration.selectionLimit = 0
        
        let picker = PHPickerViewController(configuration: configuration)
        
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    //撥打按鈕
    @IBAction func buttonCall(_ sender: UIButton)
    {
        if let phoneNumber = txtPhone.text
        {
            let url = URL(string: "tel://\(phoneNumber)")
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        }
        
    }
    
    //導航到特定地址的按鈕
    @IBAction func buttonNaviToAddress(_ sender: UIButton)
    {
        //初始化地理資訊編碼器
        let geoCoder = CLGeocoder()
        
        geoCoder.geocodeAddressString(txtAddress.text!) {
            placemarks, error in
            //沒有錯誤時，表示地址可以順利編碼成經緯度資訊
            if error == nil
            {
                //可以取得經緯度資訊時
                if placemarks != nil
                {
                    //Step1.
                    //(第一層)取得地址對應的經緯度資訊的位置標示
                    let toPlaceMark = placemarks!.first!
                    //(第二層)將經緯度資訊的位置標示轉換成導航地圖上目的地的大頭針
                    let toPin = MKPlacemark(placemark: toPlaceMark)
                    //(第三層)產生導航地圖上導航終點的大頭針
                    let destMapItem = MKMapItem(placemark: toPin)
                    //Step2.設定導航為開車模式
                    let naviOption = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                    //Step3.使用(第三層)來開啟導航地圖
                    destMapItem.openInMaps(launchOptions: naviOption)
                }
            }
            else
            {
                print("地址解碼錯誤：\(error!.localizedDescription)")
            }
        }
    }
    //修改資料按鈕
    @IBAction func buttonUpdate(_ sender: UIButton)
    {
        //Step1.更新資料庫資料
        //--to do--
        //Step2.更新離線資料集（從介面直接取得已更新的資料，重設上一頁離線資料集的當筆資料）
        myTableVC.arrTable[currentRow] = Student(no: lblNo.text!, name: txtName.text!, gender: "\(pkvGender.selectedRow(inComponent: 0))", picture: "缺大頭照", phone: txtPhone.text!, address: txtAddress.text!, email: txtEmail.text!, myclass: txtMyclass.text!)
//        print("修改後陣列：\(myTableVC.arrTable)")
        //Step3.重整上一頁的表格資料
        myTableVC.tableView.reloadData()
        //Step4.提示修改成功訊息
        //4-1.初始化訊息視窗
        let alertController = UIAlertController(title: "資料庫訊息", message: "資料修改成功", preferredStyle: .alert)
        //4-2.初始化訊息視窗使用的按鈕
        let okAction = UIAlertAction(title: "確定", style: .default, handler: nil)
        //4-3.將按鈕加入訊息視窗
        alertController.addAction(okAction)
        //4-4.顯示訊息視窗
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    
    //MARK: - View Life Cycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.view.backgroundColor = .systemFill
        //<方法二>哪一個儲存格被點選
        currentRow = myTableVC.tableView.indexPathForSelectedRow!.row
        //由上一頁的陣列紀錄當筆資料
        currentData = myTableVC.arrTable[currentRow]
//        print("上一頁的\(currentRow)被點選")
        //將資料顯示在介面上
        lblNo.text = currentData.no
        txtName.text = currentData.name
        if currentData.gender == "0"
        {
            txtGender.text = "女"
        }
        else
        {
            txtGender.text = "男"
        }
        //準備網路傳輸物件
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        
        //準備取得大頭照的URL物件
        url = URL(string: webDomain + myTableVC.arrTable[currentRow].picture)
        //準備大頭照的資料傳輸任務
        if url != nil
        {
            dataTask = session.dataTask(with: url, completionHandler: {
                imgData, response, error
                in
                if error == nil
                {
                    //轉回主要執行緒顯示大頭照
                    DispatchQueue.main.async {
                        if let picData = imgData
                        {
                            self.imgPicture.image = UIImage(data: picData)
                        }
                    }
                }
                else
                {
                    print("無法取得大頭照：\(error!.localizedDescription)")
                }
            })
            //執行取得大頭照的傳輸任務
            dataTask.resume()
        }
        
        txtPhone.text = currentData.phone
        txtMyclass.text = currentData.myclass
        txtAddress.text = currentData.address
        txtEmail.text = currentData.email
        //建立性別與班別的滾輪，讓tag的索引值與textfield的tag對應
        pkvGender = UIPickerView()
        pkvGender.tag = 2
        pkvClass = UIPickerView()
        pkvClass.tag = 5
        //指定在此類別實作pickerView相關的代理事件
        pkvGender.delegate = self
        pkvGender.dataSource = self
        pkvClass.delegate = self
        pkvClass.dataSource = self
        //將性別和班別的輸入鍵盤替換為pickerView
        txtGender.inputView = pkvGender
        txtMyclass.inputView = pkvClass
        //選定目前資料所在的性別滾輪
        pkvGender.selectRow(Int(currentData.gender)!, inComponent: 0, animated: false)
        
        for (index,item) in arrClass.enumerated()
        {
            //比對是否符合當筆的班別資料
            if item == currentData.myclass
            {
                //以比對到的索引值選定班別的pickerView
                pkvClass.selectRow(index, inComponent: 0, animated: false)
                break   //比對到符合資料即離開迴圈
            }
        }
        //取得此App通知中心的實體
        let notificationCenter = NotificationCenter.default
        //註冊虛擬鍵盤彈出通知
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        //註冊虛擬鍵盤收合通知
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    //MARK: - Touch Event
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesBegan(touches, with: event)
        print("觸碰開始！！！")
        //結束編輯狀態，收起鍵盤
        self.view.endEditing(true)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesMoved(touches, with: event)
        
        print("觸碰中移動！！！\(touches.first!.location(in: self.view))")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesEnded(touches, with: event)
        print("觸碰結束！！！")
    }
    
    //MARK: - UIPickerViewDataSource
    //滾輪有幾段
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    //每一段滾輪有幾行
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        switch pickerView.tag
        {
            //性別滾輪
            case 2:
                return arrGender.count
            //班別滾輪
            case 5:
                return arrClass.count
            default:
                return 1
        }
    }
    
    //MARK: - UIPickerViewDelegate
    //詢問每一段每一列要呈現文字
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        switch pickerView.tag
        {
            //性別滾輪
            case 2:
                return arrGender[row]
            //班別滾輪
            case 5:
                return arrClass[row]
            default:
                return "X"
        }
    }
    //pickerView被選定時
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        switch pickerView.tag
        {
            //性別滾輪
            case 2:
                txtGender.text = arrGender[row]
            //班別滾輪
            case 5:
                txtMyclass.text = arrClass[row]
            default:
                break
        }
    }
 
    //MARK: - UIImagePickerControllerDelegate
    //注意：iOS15之後只會有"相機"使用此代理事件（iOS14之前相機和相簿都使用此事件）
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        print("info:\(info)")
        //從字典中取得相機的照片
        let image = info[.originalImage] as! UIImage
        //將取得的照片直接顯示在畫面上
        imgPicture.image = image
        //退掉相機或相簿畫面
        picker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - PHPickerViewControllerDelegate
    //注意：iOS15之後"相簿"使用此代理事件
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult])
    {
        print("挑選到的照片：\(results)")
        
        if let itemProvider = results.first?.itemProvider
        {
            if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier)
            {
                itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) {
                    data, error
                    in
                    //如果沒有取得照片資料就離開
                    guard let photoData = data
                    else
                    {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        //將取到的照片呈現在介面上
                        self.imgPicture.image = UIImage(data: photoData)
                        //退掉相簿畫面
                        picker.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
}
