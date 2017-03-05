// Router.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import Auth0

protocol Navigable {

    func reload(withConnections connections: Connections)
    func navigate(_ route: Route)

    func present(_ controller: UIViewController)

    func exit(withError error: Error)

    func resetScroll(_ animated: Bool)
    func scroll(toPosition: CGPoint, animated: Bool)

}

struct Router: Navigable {
    weak var controller: LockViewController?

    let user = User()
    let lock: Lock

    init(lock: Lock, controller: LockViewController) {
        self.controller = controller
        self.lock = lock
    }

    var root: Presentable? {
        let connections = self.lock.connections
        guard !connections.isEmpty else {
            self.lock.logger.debug("No connections configured. Loading client info from Auth0...")
            let interactor = CDNLoaderInteractor(baseURL: self.lock.authentication.url, clientId: self.lock.authentication.clientId)
            return ConnectionLoadingPresenter(loader: interactor, navigator: self, dispatcher: lock.observerStore, options: self.lock.options)
        }

        let whitelistForActiveAuth = self.lock.options.enterpriseConnectionUsingActiveAuth
        switch (connections.database, connections.oauth2, connections.enterprise) {
                // Database root
            case (.some(let database), let oauth2, let enterprise):
                guard self.lock.options.allow != [.ResetPassword] && self.lock.options.initialScreen != .resetPassword else { return forgotPassword }
                let authentication = self.lock.authentication
                let interactor = DatabaseInteractor(connection: database, authentication: authentication, user: self.user, options: self.lock.options, dispatcher: lock.observerStore)
                let presenter = DatabasePresenter(interactor: interactor, connection: database, navigator: self, options: self.lock.options)
                if !oauth2.isEmpty {
                    let interactor = Auth0OAuth2Interactor(webAuth: self.lock.webAuth, dispatcher: lock.observerStore, options: self.lock.options)
                    presenter.authPresenter = AuthPresenter(connections: oauth2, interactor: interactor, customStyle: self.lock.style.oauth2)
                }
                if !enterprise.isEmpty {
                    let authInteractor = Auth0OAuth2Interactor(webAuth: self.lock.webAuth, dispatcher: lock.observerStore, options: self.lock.options)
                    let interactor = EnterpriseDomainInteractor(connections: connections, user: self.user, authentication: authInteractor)
                    presenter.enterpriseInteractor = interactor
                }
                return presenter
                // Single Enterprise with active auth support (e.g. AD)
            case (nil, let oauth2, let enterprise) where oauth2.isEmpty && enterprise.hasJustOne(andIn: whitelistForActiveAuth):
                guard let connection = enterprise.first else { return nil }
                return enterpriseActiveAuth(connection: connection, domain: connection.domains.first)
                // Single Enterprise with support for passive auth only (web auth) and some social connections
            case (nil, let oauth2, let enterprise) where enterprise.hasJustOne(andNotIn: whitelistForActiveAuth):
                guard let connection = enterprise.first else { return nil }
                let authInteractor = Auth0OAuth2Interactor(webAuth: self.lock.webAuth, dispatcher: lock.observerStore, options: self.lock.options)
                let connections: [OAuth2Connection] = oauth2 + [connection]
                return AuthPresenter(connections: connections, interactor: authInteractor, customStyle: self.lock.style.oauth2)
                // Social connections only
            case (nil, let oauth2, let enterprise) where enterprise.isEmpty:
                let interactor = Auth0OAuth2Interactor(webAuth: self.lock.webAuth, dispatcher: lock.observerStore, options: self.lock.options)
                let presenter = AuthPresenter(connections: oauth2, interactor: interactor, customStyle: self.lock.style.oauth2)
                return presenter
                // Multiple enterprise connections and maybe some social
            case (nil, let oauth2, let enterprise) where !enterprise.isEmpty:
                let authInteractor = Auth0OAuth2Interactor(webAuth: self.lock.webAuth, dispatcher: lock.observerStore, options: self.lock.options)
                let interactor = EnterpriseDomainInteractor(connections: connections, user: self.user, authentication: authInteractor)
                let presenter = EnterpriseDomainPresenter(interactor: interactor, navigator: self, options: self.lock.options)
                if !oauth2.isEmpty {
                    presenter.authPresenter = AuthPresenter(connections: connections.oauth2, interactor: authInteractor, customStyle: self.lock.style.oauth2)
                }
                return presenter
                // Not supported connections configuration
            default:
                return nil
        }
    }

    var forgotPassword: Presentable? {
        let connections = self.lock.connections
        guard !connections.isEmpty else {
            exit(withError: UnrecoverableError.clientWithNoConnections)
            return nil
        }
        let interactor = DatabasePasswordInteractor(connections: connections, authentication: self.lock.authentication, user: self.user, dispatcher: lock.observerStore)
        let presenter =  DatabaseForgotPasswordPresenter(interactor: interactor, connections: connections, navigator: self, options: self.lock.options)
        presenter.customLogger = self.lock.logger
        return presenter
    }

    var multifactor: Presentable? {
        let connections = self.lock.connections
        guard let database = connections.database else {
            exit(withError: UnrecoverableError.missingDatabaseConnection)
            return nil
        }
        let authentication = self.lock.authentication
        let interactor = MultifactorInteractor(user: self.user, authentication: authentication, connection: database, options: self.lock.options, dispatcher: lock.observerStore)
        let presenter = MultifactorPresenter(interactor: interactor, connection: database, navigator: self)
        presenter.customLogger = self.lock.logger
        return presenter
    }

    func enterpriseActiveAuth(connection: EnterpriseConnection, domain: String?) -> Presentable? {
        let authentication = self.lock.authentication
        let interactor = EnterpriseActiveAuthInteractor(connection: connection, authentication: authentication, user: self.user, options: self.lock.options, dispatcher: lock.observerStore)
        let presenter = EnterpriseActiveAuthPresenter(interactor: interactor, options: self.lock.options, domain: domain)
        presenter.customLogger = self.lock.logger
        return presenter
    }

    func unrecoverableError(_ error: UnrecoverableError) -> Presentable? {
        let presenter = UnrecoverableErrorPresenter(error: error, navigator: self)
        return presenter
    }

    var showBack: Bool {
        guard let routes = self.controller?.routes else { return false }
        return !routes.history.isEmpty
    }

    func onBack() -> () {
        guard let current = self.controller?.routes.back() else { return }

        self.user.reset()

        let style = self.lock.style

        self.lock.logger.debug("Back pressed. Showing \(current)")
        switch current {
        case .forgotPassword:
            self.controller?.present(self.forgotPassword, title: current.title(withStyle: style))
        case .root:
            self.controller?.present(self.root, title: style.hideTitle ? nil : style.title)
        default:
            break
        }
    }

    func reload(withConnections connections: Connections) {
        self.lock.connectionProvider = ConnectionProvider(local: connections, allowed: self.lock.connectionProvider.allowed)
        let connections = self.lock.connections
        self.lock.logger.debug("Reloading Lock with connections \(connections).")
        guard !connections.isEmpty else { return exit(withError: UnrecoverableError.clientWithNoConnections) }
        self.controller?.routes.reset()
        self.controller?.present(self.root, title: self.controller?.routes.current.title(withStyle: self.lock.style))
    }

    func navigate(_ route: Route) {
        let presentable: Presentable?
        switch route {
        case .root where self.controller?.routes.current != .root:
            presentable = self.root
        case .forgotPassword:
            presentable = self.forgotPassword
        case .multifactor:
            presentable = self.multifactor
        case .enterpriseActiveAuth(let connection, let domain):
            presentable = self.enterpriseActiveAuth(connection: connection, domain: domain)
        case .unrecoverableError(let error):
            presentable = self.unrecoverableError(error)
        default:
            self.lock.logger.warn("Ignoring navigation \(route)")
            return
        }
        self.lock.logger.debug("Navigating to \(route)")
        self.controller?.routes.go(route)
        self.controller?.present(presentable, title: route.title(withStyle: self.lock.style))
    }

    func present(_ controller: UIViewController) {
        self.controller?.present(controller, animated: true, completion: nil)
    }

    func resetScroll(_ animated: Bool) {
        self.controller?.scrollView.setContentOffset(CGPoint.zero, animated: animated)
    }

    func scroll(toPosition: CGPoint, animated: Bool) {
        self.controller?.scrollView.setContentOffset(toPosition, animated: animated)
    }

    func exit(withError error: Error) {
        let controller = self.controller?.presentingViewController
        let lock = self.lock
        self.lock.logger.debug("Dismissing Lock with error \(error)")
        Queue.main.async {
            controller?.dismiss(animated: true, completion: { _ in
                lock.observerStore.onFailure(error)
            })
        }
    }
}

private extension Array where Element: OAuth2Connection {
    func hasJustOne(andIn list: [String]) -> Bool {
        guard let connection = self.first, self.count == 1 else { return false }
        return list.contains(connection.name)
    }

    func hasJustOne(andNotIn list: [String]) -> Bool {
        guard let connection = self.first, self.count == 1 else { return false }
        return !list.contains(connection.name)
    }
}
