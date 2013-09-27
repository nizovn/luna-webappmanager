/*
 * This file was generated by qdbusxml2cpp version 0.8
 * Command line was: qdbusxml2cpp agent.xml -a agentadaptor
 *
 * qdbusxml2cpp is Copyright (C) 2013 Digia Plc and/or its subsidiary(-ies).
 *
 * This is an auto-generated file.
 * Do not edit! All changes made to it will be lost.
 */

#include "agentadaptor.h"
#include <QtCore/QMetaObject>
#include <QtCore/QByteArray>
#include <QtCore/QList>
#include <QtCore/QMap>
#include <QtCore/QString>
#include <QtCore/QStringList>
#include <QtCore/QVariant>

/*
 * Implementation of adaptor class AgentAdaptor
 */

AgentAdaptor::AgentAdaptor(QObject *parent)
    : QDBusAbstractAdaptor(parent)
{
    // constructor
    setAutoRelaySignals(true);
}

AgentAdaptor::~AgentAdaptor()
{
    // destructor
}

void AgentAdaptor::Cancel()
{
    // handle method call org.bluez.Agent.Cancel
    QMetaObject::invokeMethod(parent(), "Cancel");
}

void AgentAdaptor::DisplayPasskey(const QDBusObjectPath &device, uint passkey, uchar entered)
{
    // handle method call org.bluez.Agent.DisplayPasskey
    QMetaObject::invokeMethod(parent(), "DisplayPasskey", Q_ARG(QDBusObjectPath, device), Q_ARG(uint, passkey), Q_ARG(uchar, entered));
}

void AgentAdaptor::Release()
{
    // handle method call org.bluez.Agent.Release
    QMetaObject::invokeMethod(parent(), "Release");
}

void AgentAdaptor::RequestConfirmation(const QDBusObjectPath &device, uint passkey)
{
    // handle method call org.bluez.Agent.RequestConfirmation
    QMetaObject::invokeMethod(parent(), "RequestConfirmation", Q_ARG(QDBusObjectPath, device), Q_ARG(uint, passkey));
}

uint AgentAdaptor::RequestPasskey(const QDBusObjectPath &device)
{
    // handle method call org.bluez.Agent.RequestPasskey
    uint passkey;
    QMetaObject::invokeMethod(parent(), "RequestPasskey", Q_RETURN_ARG(uint, passkey), Q_ARG(QDBusObjectPath, device));
    return passkey;
}

QString AgentAdaptor::RequestPinCode(const QDBusObjectPath &device)
{
    // handle method call org.bluez.Agent.RequestPinCode
    QString pincode;
    QMetaObject::invokeMethod(parent(), "RequestPinCode", Q_RETURN_ARG(QString, pincode), Q_ARG(QDBusObjectPath, device));
    return pincode;
}

