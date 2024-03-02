import React, { useState, useEffect } from "react";
import { Divider, Grid, Message, Transition } from "semantic-ui-react";
import Greeting from "./Graphs/Greet";
import StatusChart from "./Graphs/StatusChart";
import SlStatistics from "./Graphs/SlStatistics";
import Heatmap from "./Graphs/Heatmap";
import Activity from "./Graphs/RecentActivity";
import AtAGlance from "./Graphs/Widgets/AtAGlance";

// All the props as in the controller
const Dashboard = ({
  currentUser,
  monthRange,
  states,
  state_count,
  counties,
  tile_count,
  tile_flown,
  flown,
  tile_shipped,
  shipped,
  recentActivities,
}) => {
  const [visible, setVisible] = useState(false);

  // Transitions only work if they are flipped from false to true
  useEffect(() => {
    setVisible(true);
  }, []);

  // console.log("DASHBOARD", {
  //   currentUser,
  //   monthRange,
  //   states,
  //   counties,
  //   tile_count,
  //   tile_flown,
  //   flown,
  //   tile_shipped,
  //   shipped,
  //   recentActivities,
  // });

  // currentUser isnt signed in
  if (!currentUser) {
    return (
      <Message>
        <Message.Header>You are not Signed In</Message.Header>
        <p>Sign in to access the application.</p>
      </Message>
    );
  }
  // Awaiting approval
  if (!currentUser.approved) {
    return (
      <Message>
        <Message.Header>Hello {currentUser.first_name}!</Message.Header>
        <p>You are awaiting approval. You will receive an email shortly.</p>
      </Message>
    );
  }

  return (
    <div className="homepage">
      {/* MessageBox */}

      <Transition visible={visible} animation="fade down" duration={1000}>
        <Message className="dashmessage">
          <Message.Header>
            {/* Rendering greeting and passing props */}
            <Greeting first_name={currentUser.first_name} />
          </Message.Header>
          <p className="dash-header">
            You are signed in as {currentUser.role}.
          </p>
        </Message>
      </Transition>
      {/* Import SL Statistics and pass props */}
      <Divider />
      <Grid stackable>
        <Grid.Row
          className="mobile hidden tablet hidden"
          style={{ paddingBottom: "0" }}
        >
          <Grid.Column mobile={16} tablet={16} computer={16}>
            <SlStatistics
              states={state_count}
              counties={counties}
              tile_count={tile_count}
              tile_flown={tile_flown}
              flown={flown}
              tile_shipped={tile_shipped}
              shipped={shipped}
            />
            <Divider style={{ marginBottom: "0" }} />
          </Grid.Column>
        </Grid.Row>
        <Grid.Column mobile={16} tablet={16} computer={10}>
          {/* Get Widgets which contains the other Widgets and GET req */}
          <AtAGlance />
          {/* Status Chart */}
          <StatusChart
            project={"SL"}
            month_range={monthRange}
            states={states}
          />
        </Grid.Column>

        {/* Heatmap */}
        <Grid.Column mobile={16} tablet={16} computer={6}>
          <Heatmap />
          {/* Recent Activity */}
          <Activity recentActivities={recentActivities} />
        </Grid.Column>
      </Grid>
    </div>
  );
};
export default Dashboard;
