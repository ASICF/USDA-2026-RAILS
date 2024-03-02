import React, { useState, useEffect } from "react";
import {
  Card,
  Header,
  Feed,
  Label,
  Divider,
  Transition,
} from "semantic-ui-react";

const Activity = ({ recentActivities }) => {
  const [visible, setVisible] = useState(false);

  // Transitions only work if they are flipped from false to true
  useEffect(() => {
    setVisible(true);
  }, []);

  const actionArray = [
    "executed",
    "performed",
    "ran",
    "completed",
    "finalized",
    "built",
    "established",
  ];

  return (
    <Transition visible={visible} animation="fade up" duration={1000}>
      <Card fluid>
        <Card.Content>
          <Header as="h3">Recent Activity</Header>
          <Divider />
          {recentActivities !== null && (
            <Feed size="small">
              {recentActivities.map((record, index) => (
                <Feed.Event key={index}>
                  <Feed.Content>
                    <Feed.Summary
                      style={{ fontWeight: "normal", marginBottom: "5px" }}
                    >
                      <Label>{record.user}</Label>{" "}
                      {actionArray[Math.floor(Math.random() * 7)]}{" "}
                      <b>{record.action_type}</b>{" "}
                      <i title={record.created_at}>{record.time_offset} ago</i>
                    </Feed.Summary>
                  </Feed.Content>
                </Feed.Event>
              ))}
            </Feed>
          )}
        </Card.Content>
      </Card>
    </Transition>
  );
};

export default Activity;
