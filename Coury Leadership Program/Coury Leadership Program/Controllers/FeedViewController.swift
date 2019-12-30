//
//  FeedViewController.swift
//  Coury Leadership Program
//
//  Created by Hayden Shively on 2/8/19.
//  Copyright © 2019 USC Marshall School of Business. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class FeedViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private var hasProfile: Bool = false
    private var hasContent: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        engageTableView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.contentInset = UIEdgeInsets(top: self.view.safeAreaInsets.top + 12.0, left: 0.0, bottom: 12.0, right: 0.0)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Profile
        if (BasicInformation.uid == nil) && !CLPProfile.shared.isSigningIn {presentSignInVC()}
        CLPProfile.shared.onFetchSuccess {
            print("Got profile")
            self.hasProfile = true
            self.possiblyUpdate()
        }
//        CLPProfile.shared.onAnswerPoll {self.possiblyUpdate()}
        
        // Feed
        Feed.shared.onFetchSuccess {
            print("Got feed")
            self.hasContent = true
            self.possiblyUpdate()
        }
        possiblyUpdate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Profile
        CLPProfile.shared.clearFetchSuccessCallbacks()
//        CLPProfile.shared.clearAnswerPollCallbacks()
        // Feed
        Calendar.clearFetchSuccessCallbacks()
        Polls.clearFetchSuccessCallbacks()
        Posts.clearFetchSuccessCallbacks()
    }

    @IBAction func unwindToFeed(_ unwindSegue: UIStoryboardSegue) {}

    func presentSignInVC() {self.performSegue(withIdentifier: "SignInSegue", sender: self)}

    func possiblyUpdate() {
        if hasProfile && hasContent {
            updateTableView()
        }
    }
}
