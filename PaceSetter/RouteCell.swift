//
//  RouteCell.swift
//  PaceSetter
//
//  Created by JessicaChen on 4/13/16.
//  Copyright © 2016 JessicaChen. All rights reserved.
//

import UIKit

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

class RouteCell: UITableViewCell {
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureForRoute(_ route: Route) {
        dateLabel.text = formatDate(route.date as Date)
        distanceLabel.text = String(format: "%.1f", route.distance) + "m"
        
        let duration = route.duration
        var durationDescritor = ""
        let hour = Int(duration / 3600)
        if hour < 100 {
            durationDescritor += String(format: "%02d", hour) + ":"
        } else {
            durationDescritor += hour.description + ":"
        }
        let minute = Int((duration - Double(hour) * 3600) / 60)
        durationDescritor += String(format: "%02d", minute) + ":"
        let second = Int(duration -  Double(hour) * 3600 - Double(minute) * 60)
        durationDescritor += String(format: "%02d", second)
        durationLabel.text = durationDescritor
    }
    
    func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }

}
