import React, { useState, useEffect } from "react";
import { Divider, Grid, Message, Transition } from "semantic-ui-react";
import Greeting from "./Graphs/Greet";
import StatusChart from "./Graphs/StatusChart";
import Statistics from "./Graphs/Statistics";
import Heatmap from "./Graphs/Heatmap";
import Activity from "./Graphs/RecentActivity";
import AtAGlance from "./Graphs/Widgets/AtAGlance";
import MileStones from "./Graphs/MileStones";

// All the props as in the controller
const Dashboard = ({
  currentUser,
  monthRange,
  sl_states,
  nri_states,
  sl,
  nri,
  recentActivities,
}) => {
  const [visible, setVisible] = useState(false);

  // Transitions only work if they are flipped from false to true
  useEffect(() => {
    setVisible(true);
  }, []);

  console.log("DASHBOARD", {
    currentUser,
    monthRange,
    sl_states,
    nri_states,
    sl,
    nri,
    recentActivities,
  });

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
            {sl && (
              <Statistics
                project={"SL"}
                states={sl.states}
                counties={sl.counties}
                tile_count={sl.tile_count}
                tile_flown={sl.tile_flown}
                flown={sl.flown}
                tile_shipped={sl.tile_shipped}
                shipped={sl.shipped}
                acres_count={sl.acres_count}
                acres_flown={sl.acres_flown}
                acres_percentage={sl.acres_percentage}
              />
            )}
            {nri && (
              <Statistics
                project={"NRI"}
                states={nri.states}
                counties={nri.counties}
                tile_count={nri.tile_count}
                tile_flown={nri.tile_flown}
                flown={nri.flown}
                tile_shipped={nri.tile_shipped}
                shipped={nri.shipped}
                acres_count={nri.acres_count}
                acres_flown={nri.acres_flown}
                acres_percentage={nri.acres_percentage}
              />
            )}
            <Divider style={{ marginBottom: "0" }} />
          </Grid.Column>
        </Grid.Row>

        <Grid.Row>
          <Grid.Column mobile={16} tablet={16} computer={10}>
            <AtAGlance />
          </Grid.Column>

          <Grid.Column mobile={16} tablet={16} computer={6}>
            <Heatmap />
          </Grid.Column>
        </Grid.Row>

        <Grid.Row>
          <Grid.Column mobile={16} tablet={16} computer={16}>
            {/* Get Widgets which contains the other Widgets and GET req */}

            <Grid stackable>
              <Grid.Row>
                <Grid.Column mobile={16} tablet={16} computer={8}>
                  <MileStones project="SL" />
                </Grid.Column>
                <Grid.Column mobile={16} tablet={16} computer={8}>
                  <MileStones project="NRI" />
                </Grid.Column>
              </Grid.Row>
            </Grid>
          </Grid.Column>
        </Grid.Row>

        <Grid.Row>
          <Grid.Column mobile={16} tablet={16} computer={10}>
            {/* Status Chart */}
            <StatusChart
              project={"SL"}
              month_range={monthRange}
              states={sl_states}
            />
            <StatusChart
              project={"NRI"}
              month_range={monthRange}
              states={nri_states}
            />
          </Grid.Column>

          <Grid.Column mobile={16} tablet={16} computer={6}>
            {/* Recent Activity */}
            <Activity recentActivities={recentActivities} />
          </Grid.Column>
        </Grid.Row>
      </Grid>
    </div>
  );
};
export default Dashboard;
