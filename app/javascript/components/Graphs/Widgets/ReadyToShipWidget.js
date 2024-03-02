import React, { useState, useEffect } from "react";
import {
  Card,
  Button,
  Header,
  List,
  Icon,
  Transition,
} from "semantic-ui-react";

function ReadyToShipWidget({ records }) {
  const [visible, setVisible] = useState(false);

  // Transitions only work if they are flipped from false to true
  useEffect(() => {
    setVisible(true);
  }, []);

  const renderColor = () => {
    if (records.overdue > 0) {
      return "red";
    } else if (
      records.due_within_seven_days > 0 ||
      records.due_within_thirty_days > 0 ||
      records.due_within_thirty_days > 0
    ) {
      return "yellow";
    } else {
      return "green";
    }
  };

  return (
    <Transition visible={visible} animation="vertical flip" duration={1000}>
      <Card color={renderColor()}>
        <Card.Content>
          <Header as="h4">Ready to Ship</Header>
        </Card.Content>
        <Card.Content>
          <List animated verticalAlign="middle">
            {records.overdue > 0 && (
              <List.Item>
                <List.Content>
                  <Icon color="red" name="circle" />
                  <b>{records.overdue} Tiles Overdue</b>
                </List.Content>
              </List.Item>
            )}
            {records.due_within_seven_days > 0 && (
              <List.Item>
                <List.Content>
                  <Icon color="orange" name="circle" />
                  <b>{records.due_within_seven_days} Tiles</b> Due within 7
                  Days
                </List.Content>
              </List.Item>
            )}
            {records.due_within_fifteen_days > 0 && (
              <List.Item>
                <List.Content>
                  <Icon color="yellow" name="circle" />
                  <b>{records.due_within_fifteen_days} Tiles</b> Due within 15
                  Days
                </List.Content>
              </List.Item>
            )}
            {records.due_within_thirty_days > 0 && (
              <List.Item>
                <List.Content>
                  <Icon color="blue" name="circle" />
                  <b>{records.due_within_thirty_days} Tiles</b> Due within 30
                  Days
                </List.Content>
              </List.Item>
            )}

            {records.overdue == 0 &&
              records.due_within_seven_days === 0 &&
              records.due_within_thirty_days === 0 &&
              records.due_within_thirty_days === 0 && (
                <List.Item>
                  <List.Content>
                    <Icon color="green" name="checkmark" />
                    All Caught Up!
                  </List.Content>
                </List.Item>
              )}
          </List>
        </Card.Content>
        <Card.Content extra>
          <Button fluid basic href="/ready_to_ship">
            View Report
          </Button>
        </Card.Content>
      </Card>
    </Transition>
  );
}

export default ReadyToShipWidget;
