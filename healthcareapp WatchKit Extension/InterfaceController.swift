

import WatchKit
import Foundation
import HealthKit

class InterfaceController: WKInterfaceController {

    //UI Storyboardのoutlet接続
    @IBOutlet var label: WKInterfaceLabel!
    @IBOutlet var messageLabel: WKInterfaceLabel!
    @IBOutlet var button: WKInterfaceButton!

    // HealthKitで扱うデータを管理するクラス(データの読み書きにはユーザの許可が必要)
    let healthStore = HKHealthStore()
    // 取得したいデータの識別子、今回は心拍数
    let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
    // 取得したデータの単位、今回はBPM
    let heartRateUnit = HKUnit(from: "count/min")
    // HealthStoreへのクエリ
    var heartRateQuery: HKQuery?

    func awakeWithContext(context: AnyObject?) {
        super.awake(withContext: context)
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        // HealthKitがデバイス上で利用できるか確認
        guard HKHealthStore.isHealthDataAvailable() else {
            self.label.setText("not available")
            return
        }

        // アクセス許可をユーザに求める
        let dataTypes = Set([self.heartRateType])
        self.healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) -> Void in
            guard success else {
                self.label.setText("not allowed")
                return
            }
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func buttonTapped() {
        if self.heartRateQuery == nil {
            // start
            // クエリ生成
            self.heartRateQuery = self.createStreamingQuery()
            // クエリ実行
            self.healthStore.execute(self.heartRateQuery!)
            self.button.setTitle("Stop")
            self.messageLabel.setText("Measuring...")
        }
        else {
            // end
            self.healthStore.stop(self.heartRateQuery!)
            self.heartRateQuery = nil
            self.button.setTitle("Start")
            self.messageLabel.setText("")
        }
    }

    // healthStoreへのクエリ生成
    // optionをinit（）で指定しているが不安
    private func createStreamingQuery() -> HKQuery {
        let predicate = HKQuery.predicateForSamples(withStart:NSDate() as Date,end:nil,options: HKQueryOptions.init())

        // HKAnchoredObjectQueryだと他のアプリケーションによる更新を検知することができる
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, samples, deletedObjects, anchor, error) -> Void in
            self.addSamples(samples: samples)
        }
        // Handler登録、上でやってるからいらないかも...
        query.updateHandler = { (query, samples, deletedObjects, anchor, error) -> Void in
            self.addSamples(samples: samples)
        }

        return query
    }

    // 取得したデータをLabelに表示
    private func addSamples(samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else {
            return
        }
        guard let quantity = samples.last?.quantity else {
            return
        }
        label.setText("\(quantity.doubleValue(for: heartRateUnit))")
    }
}
