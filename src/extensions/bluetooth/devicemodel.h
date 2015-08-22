/*
 * Copyright (C) 2013 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 * Charles Kerr <charles.kerr@canonical.com>
 */

#ifndef BLUETOOTH_DEVICE_MODEL_H
#define BLUETOOTH_DEVICE_MODEL_H

#include <QByteArray>
#include <QHash>
#include <QTimer>
#include <QList>
#include <QVariant>

#include <QAbstractListModel>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QScopedPointer>
#include <QSharedPointer>
#include <QSortFilterProxyModel>

#include "device.h"

class DeviceModel: public QAbstractListModel
{
    Q_OBJECT

public:
    explicit DeviceModel(QDBusConnection &dbus, QObject *parent = 0);
    ~DeviceModel();

    enum Roles
    {
      // Qt::DisplayRole holds device name
      TypeRole = Qt::UserRole,
      IconRole,
      StrengthRole,
      ConnectionRole,
      AddressRole,
      TrustedRole,
      LastRole = TrustedRole
    };

    // implemented virtual methods from QAbstractTableModel
    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    QHash<int,QByteArray> roleNames() const;

    QSharedPointer<Device> getDeviceFromAddress(const QString &address);
    QSharedPointer<Device> getDeviceFromPath(const QString &path);
    QString adapterName() const { return m_adapterName; }

public:
    bool isPowered() const { return m_isPowered; }
    bool isDiscovering() const { return m_isDiscovering; }
    bool isDiscoverable() const { return m_isDiscoverable; }
    void addConnectAfterPairing(const QString &address, Device::ConnectionMode mode);
    void createDevice(const QString &address, QObject *agent);
    void removeDevice(const QString &path);
    void stopDiscovery();
    void startDiscovery();
    void toggleDiscovery();
    void trySetDiscoverable(bool discoverable);

Q_SIGNALS:
    void poweredChanged(bool powered);
    void discoveringChanged(bool isDiscovering);
    void discoverableChanged(bool isDiscoverable);

private:
    QDBusConnection m_dbus;
    QDBusInterface m_bluezManager;

    void setProperties(const QMap<QString,QVariant> &properties);
    void updateProperty(const QString &key, const QVariant &value);

    QString m_adapterName;
    QString m_adapterAddress;
    bool m_isPowered = false;
    bool m_isPairable = false;
    bool m_isDiscovering = false;
    bool m_isDiscoverable = false;
    QTimer m_timer;
    QTimer m_discoverableTimer;
    void restartTimer();
    void setDiscoverable(bool discoverable);
    void setPowered(bool powered);

    QScopedPointer<QDBusInterface> m_bluezAdapter;
    void clearAdapter();
    void setAdapterFromPath(const QString &objectPath);

    QList<QSharedPointer<Device> > m_devices;
    void updateDevices();
    void addDevice(QSharedPointer<Device> &device);
    void addDevice(const QString &objectPath);
    void removeRow(int i);
    int findRowFromAddress(const QString &address) const;
    void emitRowChanged(int row);

private Q_SLOTS:
    void slotCreateFinished(QDBusPendingCallWatcher *call);
    void slotRemoveFinished(QDBusPendingCallWatcher *call);
    void slotPropertyChanged(const QString &key, const QDBusVariant &value);
    void slotTimeout();
    void slotEnableDiscoverable();
    void slotDeviceChanged();
    void slotDeviceCreated(const QDBusObjectPath &);
    void slotDeviceRemoved(const QDBusObjectPath &);
    void slotDeviceFound(const QString &, const QMap<QString,QVariant>&);
    void slotDeviceDisappeared(const QString&);
    void slotDefaultAdapterChanged(const QDBusObjectPath&);
    void slotAdapterRemoved(const QDBusObjectPath& path);
};

class DeviceFilter: public QSortFilterProxyModel
{
    Q_OBJECT

public:
    DeviceFilter() {}
    virtual ~DeviceFilter() {}
    void filterOnType(const QVector<Device::Type>);
    void filterOnConnections(Device::Connections);
    void filterOnTrusted(bool trusted);

protected:
    virtual bool filterAcceptsRow(int, const QModelIndex&) const;
    virtual bool lessThan(const QModelIndex&, const QModelIndex&) const;

private:
    QVector<Device::Type> m_types = QVector<Device::Type>();
    bool m_typeEnabled = false;
    Device::Connections m_connections = Device::Connection::Connected;
    bool m_connectionsEnabled = false;
    bool m_trustedEnabled = false;
    bool m_trustedFilter = false;
};

#endif // BLUETOOTH_DEVICE_MODEL_H
