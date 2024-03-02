import React, { useState, useEffect } from "react";
import { Message, Icon, List, Transition } from "semantic-ui-react";
export default function MessageBox({ status, title, message }) {
  const [visible, setVisible] = useState(false);
  // Transitions only work if they are flipped from false to true
  useEffect(() => {
    setVisible(true);
  }, []);
  // Renders the message which can be an array
  const renderMesage = () => {
    if (Array.isArray(message)) {
      return (
        <List bulleted>
          {message.map((line, index) => {
            return <List.Item key={index}>{line}</List.Item>;
          })}
        </List>
      );
    } else {
      return <p>{message}</p>;
    }
  };
  // Render Success Message
  if (status === "Success") {
    return (
      <Transition visible={visible} animation="pulse" duration={1000}>
        <Message icon success>
          <Icon name="checkmark" />
          <Message.Content>
            <Message.Header>{title ? title : "Success"}</Message.Header>
            {renderMesage()}
          </Message.Content>
        </Message>
      </Transition>
    );
  }
  // Render Error Message
  if (status === "Error") {
    return (
      <Transition visible={visible} animation="shake" duration={1000}>
        <Message icon error>
          <Icon name="remove" />
          <Message.Content>
            <Message.Header>{title ? title : "Error"}</Message.Header>
            {renderMesage()}
          </Message.Content>
        </Message>
      </Transition>
    );
  }
  // Render Loading Message
  if (status === "Loading") {
    return (
      <Message icon>
        <Icon name="circle notched" loading />
        <Message.Content>
          <Message.Header>{title ? title : "Loading"}</Message.Header>
          {renderMesage()}
        </Message.Content>
      </Message>
    );
  }
  // Render Warning Message
  if (status === "Warning") {
    return (
      <Transition visible={visible} animation="glow" duration={1000}>
        <Message icon warning>
          <Icon name="warning" />
          <Message.Content>
            <Message.Header>{title ? title : "Warning"}</Message.Header>
            {renderMesage()}
          </Message.Content>
        </Message>
      </Transition>
    );
  }
  // Render Info Message
  if (status === "Info") {
    return (
      <Message icon info>
        <Icon name="info" />
        <Message.Content>
          <Message.Header>{title ? title : "Info"}</Message.Header>
          {renderMesage()}
        </Message.Content>
      </Message>
    );
  }
  // render default
  return (
    <Message>
      <Message.Header>{title ? title : "Notice"}</Message.Header>
      {renderMesage()}
    </Message>
  );
}
