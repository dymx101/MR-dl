//
//  ChaptersTableViewController.swift
//  MR-dl
//
//  Created by Chen Zerui on 28/12/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import MRClient

class ChaptersTableViewController: UITableViewController {
    
    static func `init`(dataProvider: SerieDataProvider)-> ChaptersTableViewController{
        let ctr = AppDelegate.shared.storyBoard.instantiateViewController(withIdentifier: "chapterDownloadsCtr") as! ChaptersTableViewController
        ctr.serieDataProvider = dataProvider
        return ctr
    }
    
    var serieDataProvider: SerieDataProvider!
    
    var localSerie: MRSerie?{
        return serieDataProvider as? MRSerie
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hidesBarsOnSwipe = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.hidesBarsOnSwipe = false
    }
    
    private func setupUI(){
        let chaptersCount: Int = serieDataProvider[.chaptersCount]!
        navigationItem.title = "\(chaptersCount) Chapters"
        tableView.tableFooterView = UIView()
        if let serie = localSerie{
            serie.downloader.delegate = self
        }
    }
    
}


extension ChaptersTableViewController{
    
    // sections: downloaded, downloading
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return serieDataProvider.numberOfChapters(ofState: DownloadState(rawValue: section)!)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: ChapterTableViewCell.identifier) as! ChapterTableViewCell
            cell.chapterDataProvider = serieDataProvider.chapter(atIndex: indexPath.row, forState: DownloadState(rawValue: 0)!)
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: ChapterDownloadTableViewCell.identifier) as! ChapterDownloadTableViewCell
            cell.chapter = serieDataProvider.chapter(atIndex: indexPath.row, forState: DownloadState(rawValue: 1)!) as! MRChapter
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0{
            return "\(serieDataProvider.numberOfChapters(ofState: .downloaded)) Downloaded"
        }
        return "\(serieDataProvider.numberOfChapters(ofState: .notDownloaded)) Not downloaded"
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewChapterCtr = ChapterImagesPageViewController(dataProvider: serieDataProvider, atChapter: indexPath.row)
        navigationController?.pushViewController(viewChapterCtr, animated: true)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }


    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let serie = localSerie else{
            // no download/delete action if source is remote
            return nil
        }
        if indexPath.section == 0{
            // incomplete implementation here, will allow deleting chapter's images from disk
            return nil
        }
        // is first in download queue
        if serie.downloader.notDownloadedChapters[indexPath.row].downloader.state == .notDownloaded{
            let pauseAction = UIContextualAction.init(style: .normal, title: "Pause", handler: { (_, _, completion) in
                serie.downloader.cancelDownload()
                completion(true)
            })
        pauseAction.backgroundColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
            return UISwipeActionsConfiguration(actions: [pauseAction])
        }
        let beginAction = UIContextualAction(style: .normal, title: "Download") { (_, _, completion) in
            serie.downloader.beginDownload(forIndex: indexPath.row)
            self.tableView.moveRow(at: indexPath, to: IndexPath(row: 0, section: 1))
            completion(true)
        }
        beginAction.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.6647321429, blue: 1, alpha: 1)
        return UISwipeActionsConfiguration(actions: [beginAction])
    }

}

extension ChaptersTableViewController: MRSerieDownloaderDelegate{
    
    // reload row to reflect progress change
    // TODO: use visible-only reload
    func downloaderDidDownload(chapter: MRChapter, page: Int, error: Error?) {
        if let index = localSerie!.downloader.notDownloadedChapters.index(of: chapter){
            // sync to block current thread from modifying data before ui change is applied
            DispatchQueue.main.sync {
                self.tableView.reloadRows(at: [IndexPath(row: index, section: 1)], with: .none)
            }
        }
    }
    
    // 'move' row from downloading section (1) to downloaded section (0)
    func downloaderDidComplete(chapter: MRChapter, originalIndex: Int) {
        if let index = localSerie!.downloader.downloadedChapters.index(of: chapter){
            DispatchQueue.main.async {
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: [IndexPath(row: originalIndex, section: 1)], with: .automatic)
                self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                self.tableView.endUpdates()
            }
        }
    }
    
    
}
